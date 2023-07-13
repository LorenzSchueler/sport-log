import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/step_count_utils.dart';
import 'package:sport_log/helpers/tracking_ui_utils.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/cardio/audio_feedback_config.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

enum TrackingMode { notStarted, tracking, paused }

class TrackingUtils extends ChangeNotifier {
  TrackingUtils({required TrackingSettings trackingSettings})
      : _cardioSessionDescription = CardioSessionDescription(
          cardioSession:
              CardioSession.defaultValue(trackingSettings.movement.id)
                ..cardioType = trackingSettings.cardioType
                ..time = Duration.zero
                ..track = []
                ..cadence = []
                ..heartRate = []
                ..routeId = trackingSettings.route?.id,
          movement: trackingSettings.movement,
          route: trackingSettings.route,
        ),
        _routeAlarmDistance = trackingSettings.route?.track != null
            ? trackingSettings.routeAlarmDistance
            : null,
        _audioFeedbackConfig = trackingSettings.audioFeedback,
        _heartRateUtils = trackingSettings.heartRateUtils.deviceId != null
            ? (HeartRateUtils() // trackingSettings.heartRateUtils is disposed
              ..deviceId = trackingSettings.heartRateUtils.deviceId)
            : null;

  static const _maxSpeed = 250; // km/ h
  static const currentDurationOffset = Duration(minutes: 1);
  static const _minAlarmInterval = Duration(minutes: 1);

  final _dataProvider = CardioSessionDescriptionDataProvider();

  final CardioSessionDescription _cardioSessionDescription;
  CardioSessionDescription get cardioSessionDescription =>
      _cardioSessionDescription;
  bool _isSaved = false;

  TrackingMode _trackingMode = TrackingMode.notStarted;
  TrackingMode get mode => _trackingMode;
  bool get isTracking => _trackingMode == TrackingMode.tracking;
  late DateTime _lastResumeTime;
  Duration _lastStopDuration = Duration.zero;

  Duration get currentDuration => isTracking
      ? _lastStopDuration + DateTime.now().difference(_lastResumeTime)
      : _lastStopDuration;

  String _locationInfo = "no data";
  String get locationInfo => _locationInfo;
  String _stepInfo = "no data";
  String get stepInfo => _stepInfo;
  String _heartRateInfo = "no data";
  String get heartRateInfo => _heartRateInfo;

  Timer? _refreshTimer;
  Timer? _autosaveTimer;

  final TrackingUiUtils _trackingUiUtils = TrackingUiUtils();
  void setCenterLocation(bool centerLocation) => _trackingUiUtils
      .setCenterLocation(centerLocation, _locationUtils.lastLatLng);

  final LocationUtils _locationUtils = LocationUtils();
  bool get waitingOnGps => !_locationUtils.hasGps;

  final StepCountUtils _stepUtils = StepCountUtils();

  final HeartRateUtils? _heartRateUtils;
  bool get waitingOnHR => _heartRateUtils?.isNotConnected ?? false;

  ElevationMapController? _elevationMapController;

  final int? _routeAlarmDistance;
  DateTime? _lastAlarm;
  final _tts = FlutterTts()
    ..setVoice({"name": "en-US-language", "locale": "en-US"})
    ..awaitSpeakCompletion(true);

  final AudioFeedbackConfig? _audioFeedbackConfig;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _autosaveTimer?.cancel();
    _stepUtils.dispose();
    _locationUtils.dispose();
    _heartRateUtils?.dispose();
    super.dispose();
  }

  Future<void> onMapCreated(MapController mapController) async {
    await _trackingUiUtils.onMapCreated(
      mapController,
      cardioSessionDescription.route,
    );
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    _autosaveTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _autoSaveCardioSession(),
    );
    await _locationUtils.startLocationStream(_onLocationUpdate);
    await _stepUtils.startStepStream(_onStepUpdate);
    await _heartRateUtils?.startHeartRateStream(_onHeartRateUpdate);
  }

  void onElevationMapCreated(ElevationMapController mapController) {
    _elevationMapController = mapController;
  }

  void start() {
    _trackingMode = TrackingMode.tracking;
    _lastResumeTime = DateTime.now();
    _cardioSessionDescription.cardioSession.datetime = _lastResumeTime;
    notifyListeners();
  }

  void resume() {
    _trackingMode = TrackingMode.tracking;
    _lastResumeTime = DateTime.now();
    notifyListeners();
  }

  void pause() {
    _trackingMode = TrackingMode.paused;
    _lastStopDuration += DateTime.now().difference(_lastResumeTime);
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
      if (result.isSuccess) {
        onSuccess();
      } else {
        await showMessageDialog(
          context: context,
          text: 'Saving Cardio Session failed:\n${result.failure}',
        );
      }
    }
  }

  Future<void> saveCardioSession(BuildContext context) async {
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
      final result =
          await _dataProvider.deleteSingle(_cardioSessionDescription);
      if (context.mounted && result.isFailure) {
        await showMessageDialog(
          context: context,
          text: 'Deleting Cardio Session failed:\n${result.failure}',
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
    notifyListeners();
  }

  void _onHeartRateUpdate(List<int> rrs) {
    final heartRate = _cardioSessionDescription.cardioSession.heartRate!;

    if (isTracking) {
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
    if (isTracking) {
      _cardioSessionDescription.cardioSession.cadence!.add(currentDuration);
    }
    _stepInfo = "last step: $currentDuration";
  }

  Future<void> _onLocationUpdate(GpsPosition location) async {
    final track = _cardioSessionDescription.cardioSession.track!;

    // filter GPS jumps in tracking mode
    if (isTracking && track.isNotEmpty) {
      final lastPosition = track.last;
      final km = lastPosition.latLng.distanceTo(location.latLng) / 1000;
      final hour = (currentDuration - lastPosition.time).inHourFractions;
      final speed = km / hour;
      if (speed > _maxSpeed) {
        return;
      }
    }

    final elevation =
        await _elevationMapController?.getElevation(location.latLng);

    final position = Position(
      latitude: location.latitude,
      longitude: location.longitude,
      elevation: elevation ?? location.elevation,
      distance: track.isEmpty
          ? 0
          : track.last.distance + track.last.latLng.distanceTo(location.latLng),
      time: currentDuration,
    );

    _locationInfo = "accuracy: ${location.accuracy.round()} m\n"
        "satellites: ${location.satellites}\n"
        "elevation GPS: ${location.elevation.round()} m\n"
        "elevation Mbx: ${elevation?.round()} m\n"
        "points:      ${track.length}";

    if (isTracking) {
      track.add(position);
      await _trackingUiUtils
          .onTrackUpdate(_cardioSessionDescription.cardioSession.track);
    }
    await _trackingUiUtils.onLocationUpdate(location);

    await _routeAlarm(position);
    await _audioFeedback();
  }

  Future<void> _routeAlarm(Position position) async {
    if (isTracking &&
        _routeAlarmDistance != null &&
        (_lastAlarm?.isBefore(DateTime.now().subtract(_minAlarmInterval)) ??
            true)) {
      final (distance, index) =
          position.minDistanceTo(cardioSessionDescription.route!.track!);
      if (distance > _routeAlarmDistance! && index != null) {
        _lastAlarm = DateTime.now();
        await _tts.speak("You are off route by ${distance.round()} meters.");
      }
    }
  }

  Future<void> _audioFeedback() async {
    final session = _cardioSessionDescription.cardioSession;
    final track = session.track!;
    if (isTracking && _audioFeedbackConfig != null && track.length >= 2) {
      final config = _audioFeedbackConfig!;
      final prevLap = track[track.length - 2].distance ~/ config.interval;
      final currLap = track.last.distance ~/ config.interval;
      if (prevLap < currLap) {
        await _tts.speak("The current metrics are:");
        for (final metric in config.metrics) {
          final text = metric.text(session);
          if (text != null) {
            await _tts.speak(text);
          }
        }
      }
    }
  }
}
