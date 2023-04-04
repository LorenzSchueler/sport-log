import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Position, Settings;
import 'package:pedometer/pedometer.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/step_count_utils.dart';
import 'package:sport_log/models/cardio/all.dart';
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
        _heartRateUtils = trackingSettings.heartRateUtils.deviceId != null
            ? trackingSettings.heartRateUtils
            : null;

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

  bool _centerLocation = true;
  void setCenterLocation(bool centerLocation) {
    _centerLocation = centerLocation;
    centerCurrentLocation();
  }

  String _locationInfo = "no data";
  String get locationInfo => _locationInfo;
  String _stepInfo = "no data";
  String get stepInfo => _stepInfo;
  String _heartRateInfo = "no data";
  String get heartRateInfo => _heartRateInfo;

  Timer? _refreshTimer;
  Timer? _autosaveTimer;

  final LocationUtils _locationUtils = LocationUtils();
  LatLng? get lastLatLng => _locationUtils.lastLatLng;
  final StepCountUtils _stepUtils = StepCountUtils();
  final HeartRateUtils? _heartRateUtils;
  bool get waitingOnHR => _heartRateUtils?.isNotActive ?? false;

  MapController? _mapController;
  ElevationMapController? _elevationMapController;

  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();

  final int? _routeAlarmDistance;
  DateTime? _lastAlarm;
  static const _alarmInterval = Duration(minutes: 1);
  final tts = FlutterTts()
    ..setVoice({"name": "en-US-language", "locale": "en-US"});
  //var voices = ((await tts.getVoices) as List).cast<Map>().where((m) {
  //var d = m.cast<String, String>();
  //return d["locale"] == "en-US";
  //}).toList();

  static const maxSpeed = 250;

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
    _mapController = mapController;
    if (_cardioSessionDescription.route?.track != null) {
      await _mapController
          ?.addRouteLine(_cardioSessionDescription.route!.track!);
    }
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    _autosaveTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _autoSaveCardioSession(),
    );
    await _locationUtils.startLocationStream(_onLocationUpdate);
    await _stepUtils.startStepCountStream(_onStepCountUpdate);
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

  void _onHeartRateUpdate(PolarHeartRateEvent event) {
    if (isTracking) {
      if (_cardioSessionDescription.cardioSession.heartRate!.isEmpty &&
          event.data.rrsMs.isNotEmpty) {
        _cardioSessionDescription.cardioSession.heartRate!.add(currentDuration);
      } else {
        for (final rr in event.data.rrsMs) {
          _cardioSessionDescription.cardioSession.heartRate!.add(
            currentDuration +
                Duration(milliseconds: -event.data.rrsMs.sum + rr),
          );
        }
      }
    }
    _heartRateInfo = "rr: ${event.data.rrsMs} ms\nhr: ${event.data.hr} bpm";
  }

  void _onStepCountUpdate(StepCount stepCount) {
    if (isTracking) {
      if (_cardioSessionDescription.cardioSession.cadence!.isEmpty) {
        _cardioSessionDescription.cardioSession.cadence!.add(currentDuration);
      } else {
        /// interpolate steps since last stepCount update
        final newSteps = stepCount.steps - _stepUtils.lastStepCount.steps;
        final timeDiff = stepCount.timeStamp
            .difference(_stepUtils.lastStepCount.timeStamp)
            .inMilliseconds;
        final avgTimeDiff = (timeDiff / newSteps).floor();
        for (var ms = 0; ms < timeDiff; ms += avgTimeDiff) {
          _cardioSessionDescription.cardioSession.cadence!.add(
            currentDuration + Duration(milliseconds: -timeDiff + ms),
          );
        }
      }
    }
    _stepInfo =
        "step count: ${stepCount.steps}\ntime: ${stepCount.timeStamp.formatHms}";
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    // filter GPS jumps in tracking mode
    if (isTracking &&
        _cardioSessionDescription.cardioSession.track!.isNotEmpty) {
      final lastPosition = _cardioSessionDescription.cardioSession.track!.last;
      final km = lastPosition.distanceTo(location.latLng) / 1000;
      final hour = (currentDuration - lastPosition.time).inMilliseconds /
          (1000 * 60 * 60);
      final speed = km / hour;
      if (speed > maxSpeed) {
        return;
      }
    }

    final elevation =
        await _elevationMapController?.getElevation(location.latLng);

    final position = Position(
      latitude: location.latitude!,
      longitude: location.longitude!,
      elevation: elevation ?? location.altitude!,
      distance: _cardioSessionDescription.cardioSession.track!.isEmpty
          ? 0
          : _cardioSessionDescription.cardioSession.track!.last
              .addDistanceTo(location.latLng),
      time: currentDuration,
    );

    _locationInfo = "accuracy: ${location.accuracy?.round()} m\n"
        "satellites: ${location.satellites}\n"
        "elevation GPS: ${location.altitude?.round()} m\n"
        "elevation Mbx: ${elevation?.round()} m\n"
        "points:      ${_cardioSessionDescription.cardioSession.track!.length}";

    if (isTracking) {
      _cardioSessionDescription.cardioSession.track!.add(position);
      await _mapController?.updateTrackLine(
        _line,
        _cardioSessionDescription.cardioSession.track,
      );
    }

    await centerCurrentLocation();
    await _mapController?.updateCurrentLocationMarker(
      _currentLocationMarker,
      position.latLng,
    );

    await _checkRoutDistance(position);
  }

  Future<void> _checkRoutDistance(Position position) async {
    if (isTracking &&
        _routeAlarmDistance != null &&
        (_lastAlarm?.isBefore(DateTime.now().subtract(_alarmInterval)) ??
            true)) {
      final distance = position
          .minDistanceTo(cardioSessionDescription.route!.track!)
          .round();
      if (distance > _routeAlarmDistance!) {
        _lastAlarm = DateTime.now();
        await tts.speak("You are off route by $distance meters.");
      }
    }
  }

  Future<void> centerCurrentLocation() async {
    final latLng = lastLatLng;
    if (_centerLocation && latLng != null) {
      await _mapController?.animateCenter(latLng);
    }
  }
}
