import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/helpers/alarm_utils.dart';
import 'package:sport_log/helpers/audio_feedback_utils.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/step_count_utils.dart';
import 'package:sport_log/helpers/stopwatch.dart';
import 'package:sport_log/helpers/tracking_ui_utils.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

enum TrackingMode {
  notStarted,
  tracking,
  paused;

  bool get isNotStarted => this == TrackingMode.notStarted;
  bool get isTracking => this == TrackingMode.tracking;
  bool get isPaused => this == TrackingMode.paused;
}

class TrackingUtils extends ChangeNotifier {
  TrackingUtils({required TrackingSettings trackingSettings})
    : _cardioSessionDescription = CardioSessionDescription(
        cardioSession: CardioSession.defaultValue(trackingSettings.movement.id)
          ..cardioType = trackingSettings.cardioType
          ..track = []
          ..cadence = []
          ..heartRate = []
          ..routeId = trackingSettings.route?.id,
        movement: trackingSettings.movement,
        route: trackingSettings.route,
      ),
      _trackingUiUtils = TrackingUiUtils(
        trackingSettings.route,
        trackingSettings.cardioSession,
      ),
      _alarmUtils = AlarmUtils(
        trackingSettings.route?.track != null
            ? trackingSettings.routeAlarmDistance
            : null,
      ),
      _audioFeedbackUtils = AudioFeedbackUtils(trackingSettings.audioFeedback),
      _heartRateUtils = trackingSettings.heartRateUtils.deviceId != null
          ? (HeartRateUtils() // trackingSettings.heartRateUtils is disposed
              ..deviceId = trackingSettings.heartRateUtils.deviceId)
          : null {
    _audioFeedbackUtils.setCallbacks(
      () => cardioSessionDescription.cardioSession,
      () => mode,
    );
    _alarmUtils.setCallbacks(
      () => cardioSessionDescription.cardioSession.track!,
      () => mode,
    );
  }

  static const _maxSpeed = 250; // km/ h
  static const currentDurationOffset = Duration(minutes: 1);

  final _dataProvider = CardioSessionDescriptionDataProvider();

  final CardioSessionDescription _cardioSessionDescription;
  CardioSessionDescription get cardioSessionDescription =>
      _cardioSessionDescription;
  bool _isSaved = false;

  TrackingMode _trackingMode = TrackingMode.notStarted;
  TrackingMode get mode => _trackingMode;

  final StopwatchX _stopwatch = StopwatchX();
  Duration get currentDuration => _stopwatch.elapsed;

  String _locationInfo = "no data";
  String get locationInfo => _locationInfo;
  String _stepInfo = "no data";
  String get stepInfo => _stepInfo;
  String _heartRateInfo = "no data";
  String get heartRateInfo => _heartRateInfo;

  static const _refreshInterval = Duration(seconds: 1);
  Timer? _refreshTimer;
  static const _autosaveInterval = Duration(minutes: 1);
  Timer? _autosaveTimer;

  final TrackingUiUtils _trackingUiUtils;
  void setCenterLocation(bool centerLocation) => _trackingUiUtils
      .setCenterLocation(centerLocation, _locationUtils.lastLatLng);

  final LocationUtils _locationUtils = LocationUtils(inBackground: true);
  bool get hasLocation => _locationUtils.hasLocation;
  bool get hasAccurateLocation => _locationUtils.hasAccurateLocation;

  final StepCountUtils _stepUtils = StepCountUtils();

  final HeartRateUtils? _heartRateUtils;
  bool get waitingOnHR => _heartRateUtils?.isNotConnected ?? false;

  ElevationMapController? _elevationMapController;

  final AudioFeedbackUtils _audioFeedbackUtils;
  final AlarmUtils _alarmUtils;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _autosaveTimer?.cancel();
    _stepUtils.dispose();
    _locationUtils.dispose();
    _heartRateUtils?.dispose();
    _audioFeedbackUtils.dispose();
    super.dispose();
  }

  Future<void> onMapCreated(MapController mapController) async {
    await _trackingUiUtils.onMapCreated(mapController);
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refresh());
    _autosaveTimer = Timer.periodic(
      _autosaveInterval,
      (_) => _autoSaveCardioSession(),
    );
    await _locationUtils.startLocationStream(
      onLocationUpdate: _onLocationUpdate,
      inBackground: true,
    );
    await _stepUtils.startStepStream(_onStepUpdate);
    await _heartRateUtils?.startHeartRateStream(_onHeartRateUpdate);
    if (_alarmUtils.noTts || _audioFeedbackUtils.noTts) {
      await showMessageDialog(
        // ignore: use_build_context_synchronously
        context: App.globalContext,
        title: "Warning",
        text:
            "No Text-To-Speech (TTS) engine found. Audio feedback and alarms not available.",
      );
    }
  }

  void onElevationMapCreated(ElevationMapController mapController) {
    _elevationMapController = mapController;
  }

  void start() {
    _stopwatch.start();
    _trackingMode = TrackingMode.tracking;
    _cardioSessionDescription.cardioSession.datetime = DateTime.now();
    _audioFeedbackUtils.onStart();
    notifyListeners();
  }

  void resume() {
    _stopwatch.start();
    _trackingMode = TrackingMode.tracking;
    notifyListeners();
  }

  void pause() {
    _trackingMode = TrackingMode.paused;
    _stopwatch.stop();
    notifyListeners();
  }

  Future<void> _save(BuildContext context, void Function() onSuccess) async {
    final cardioSessionDescription = _cardioSessionDescription.clone();
    cardioSessionDescription.cardioSession.time = currentDuration;
    cardioSessionDescription.cardioSession.setEmptyListsToNull();
    cardioSessionDescription.cardioSession.setAscentDescent();
    cardioSessionDescription.cardioSession.setAvgCadence();
    cardioSessionDescription.cardioSession.setAvgHeartRate();
    cardioSessionDescription.cardioSession.setDistance();
    final result = _isSaved
        ? await _dataProvider.updateSingle(cardioSessionDescription)
        : await _dataProvider.createSingle(cardioSessionDescription);
    if (context.mounted) {
      if (result.isOk) {
        onSuccess();
      } else {
        await showMessageDialog(
          context: context,
          title: "Saving Cardio Session Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> saveCardioSession(BuildContext context) async {
    _audioFeedbackUtils.onStop();
    await _save(context, () {
      Navigator.pop(context); // pop dialog
      Navigator.pop(context); // pop tracking page
      Navigator.pop(context); // pop tracking settings page
    });
  }

  Future<void> _autoSaveCardioSession() async {
    if (mode != TrackingMode.notStarted) {
      final context = App.globalContext;
      await _save(context, () => _isSaved = true);
    }
  }

  Future<void> deleteIfSaved(BuildContext context) async {
    // do not call showDeleteWarningDialog because DiscardDialog already shown
    if (_isSaved) {
      final result = await _dataProvider.deleteSingle(
        _cardioSessionDescription,
      );
      if (context.mounted && result.isErr) {
        await showMessageDialog(
          context: context,
          title: "Deleting Cardio Session Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  void _refresh() {
    // called every second
    _cardioSessionDescription.cardioSession.time = currentDuration;
    _cardioSessionDescription.cardioSession.setAscentDescent();
    _cardioSessionDescription.cardioSession.setAvgCadence();
    _cardioSessionDescription.cardioSession.setAvgHeartRate();
    _cardioSessionDescription.cardioSession.setDistance();
    _trackingUiUtils.updateSessionProgressMarker(currentDuration);
    notifyListeners();
  }

  void _onHeartRateUpdate(List<int> rrs) {
    final heartRate = _cardioSessionDescription.cardioSession.heartRate!;

    if (_trackingMode.isTracking) {
      var duration = currentDuration - Duration(milliseconds: rrs.sum);
      for (final rr in rrs) {
        duration += Duration(milliseconds: rr);
        if (!duration.isNegative) {
          heartRate.add(duration);
        }
      }
    }
    _heartRateInfo = "rr: $rrs ms";
  }

  void _onStepUpdate() {
    if (_trackingMode.isTracking) {
      _cardioSessionDescription.cardioSession.cadence!.add(currentDuration);
    }
    _stepInfo = "last step: $currentDuration";
  }

  Future<void> _onLocationUpdate(GpsPosition location) async {
    final track = _cardioSessionDescription.cardioSession.track!;

    // filter GPS jumps in tracking mode
    if (_trackingMode.isTracking && track.isNotEmpty) {
      final lastPosition = track.last;
      final km = lastPosition.latLng.distanceTo(location.latLng) / 1000;
      final hour = (currentDuration - lastPosition.time).inHourFractions;
      final speed = km / hour;
      if (speed > _maxSpeed) {
        return;
      }
    }

    final elevation = await _elevationMapController?.getElevation(
      location.latLng,
    );

    final position = Position(
      latitude: location.latitude,
      longitude: location.longitude,
      elevation: elevation ?? location.elevation,
      distance: track.isEmpty
          ? 0
          : track.last.distance + track.last.latLng.distanceTo(location.latLng),
      time: currentDuration,
    );

    _locationInfo =
        "accuracy: ${location.accuracy.round()} m\n"
        "satellites: ${location.satellites}\n"
        "elevation GPS: ${location.elevation.round()} m\n"
        "elevation Mbx: ${elevation?.round()} m\n"
        "points:      ${track.length}";

    if (_trackingMode.isTracking) {
      track.add(position);
      await _trackingUiUtils.updateTrack(
        _cardioSessionDescription.cardioSession.track,
      );
    }
    await _trackingUiUtils.updateLocation(location);

    await _audioFeedbackUtils.onNewPosition();
    await _alarmUtils.onNewPosition(position);
  }
}
