import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
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
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

enum TrackingMode { notStarted, tracking, paused }

class TrackingUtils extends ChangeNotifier {
  TrackingUtils({
    required Movement movement,
    required CardioType cardioType,
    required Route? route,
    required HeartRateUtils? heartRateUtils,
  })  : _cardioSessionDescription = CardioSessionDescription(
          cardioSession: CardioSession.defaultValue(movement.id)
            ..cardioType = cardioType
            ..time = Duration.zero
            ..track = []
            ..cadence = []
            ..heartRate = []
            ..routeId = route?.id,
          movement: movement,
          route: route,
        ),
        _heartRateUtils = heartRateUtils;

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

  MapController? _mapController;

  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();

  static const maxSpeed = 250;

  @override
  Future<void> dispose() async {
    _refreshTimer?.cancel();
    _autosaveTimer?.cancel();
    _stepUtils.stopStepCountStream();
    _locationUtils.stopLocationStream();
    await _heartRateUtils?.stopHeartRateStream();
    final lastGpsPosition = _locationUtils.lastLatLng;
    if (lastGpsPosition != null) {
      Settings.instance.lastGpsLatLng = lastGpsPosition;
    }
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

  Future<void> saveCardioSession(BuildContext context) async {
    _cardioSessionDescription.cardioSession.time = currentDuration;
    _cardioSessionDescription.cardioSession.setEmptyListsToNull();
    _cardioSessionDescription.cardioSession.setAscentDescent();
    _cardioSessionDescription.cardioSession.setAvgCadence();
    _cardioSessionDescription.cardioSession.setAvgHeartRate();
    _cardioSessionDescription.cardioSession.setDistance();
    final result = _isSaved
        ? await _dataProvider.updateSingle(_cardioSessionDescription)
        : await _dataProvider.createSingle(_cardioSessionDescription);
    if (context.mounted) {
      if (result.isSuccess) {
        Navigator.pop(context); // pop dialog
        Navigator.pop(context); // pop tracking page
        Navigator.pop(context); // pop tracking settings page
      } else {
        await showMessageDialog(
          context: context,
          text: 'Saving Cardio Session failed:\n${result.failure}',
        );
      }
    }
  }

  Future<void> _autoSaveCardioSession() async {
    if (mode != TrackingMode.notStarted) {
      final cardioSessionDescription = _cardioSessionDescription.clone();
      cardioSessionDescription.cardioSession.time = currentDuration;
      cardioSessionDescription.cardioSession.setEmptyListsToNull();
      cardioSessionDescription.cardioSession.setAscentDescent();
      cardioSessionDescription.cardioSession.setAvgCadence();
      cardioSessionDescription.cardioSession.setAvgHeartRate();
      cardioSessionDescription.cardioSession.setDistance();
      final result = _isSaved
          ? await _dataProvider.updateSingle(_cardioSessionDescription)
          : await _dataProvider.createSingle(_cardioSessionDescription);
      if (result.isSuccess) {
        _isSaved = true;
      } else {
        final context = App.globalContext;
        if (context.mounted) {
          await showMessageDialog(
            context: context,
            text: 'Saving Cardio Session failed:\n${result.failure}',
          );
        }
      }
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
      final km =
          lastPosition.distanceTo(location.latitude!, location.longitude!) /
              1000;
      final hour = (currentDuration - lastPosition.time).inMilliseconds /
          (1000 * 60 * 60);
      final speed = km / hour;
      if (speed > maxSpeed) {
        return;
      }
    }

    // TODO use elevation from mapbox
    //final elevation =
    //(await _mapController?.getElevation(location.latLng.toJsonPoint()))
    //?.round();

    _locationInfo = "provider:   ${location.provider}\n"
        "accuracy: ${location.accuracy?.round()} m\n"
        "elevation GPS: ${location.altitude?.round()} m\n"
        //"elevation Mbx: $elevation m\n"
        "time: ${location.time! ~/ 1000} s\n"
        "satellites: ${location.satelliteNumber}\n"
        "points:      ${_cardioSessionDescription.cardioSession.track?.length}";

    await centerCurrentLocation();

    await _mapController?.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
    );

    if (isTracking) {
      _cardioSessionDescription.cardioSession.track!.add(
        Position(
          latitude: location.latitude!,
          longitude: location.longitude!,
          elevation: location.altitude!,
          distance: _cardioSessionDescription.cardioSession.track!.isEmpty
              ? 0
              : _cardioSessionDescription.cardioSession.track!.last
                  .addDistanceTo(location.latitude!, location.longitude!),
          time: currentDuration,
        ),
      );
      await _mapController?.updateTrackLine(
        _line,
        _cardioSessionDescription.cardioSession.track,
      );
    }
  }

  Future<void> centerCurrentLocation() async {
    final latLng = lastLatLng;
    if (_centerLocation && latLng != null) {
      await _mapController?.animateCenter(latLng);
    }
  }
}
