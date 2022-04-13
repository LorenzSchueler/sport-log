import 'dart:async';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:polar/polar.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/step_count_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

enum TrackingMode { notStarted, tracking, paused, stopped }

class CardioTrackingPage extends StatefulWidget {
  final Movement movement;
  final CardioType cardioType;
  final Route? route;
  final String? heartRateMonitorId;

  const CardioTrackingPage({
    required this.route,
    required this.movement,
    required this.cardioType,
    required this.heartRateMonitorId,
    Key? key,
  }) : super(key: key);

  @override
  State<CardioTrackingPage> createState() => CardioTrackingPageState();
}

class CardioTrackingPageState extends State<CardioTrackingPage> {
  final _logger = Logger('CardioTrackingPage');
  final _dataProvider = CardioSessionDescriptionDataProvider();

  late CardioSessionDescription _cardioSessionDescription;

  TrackingMode _trackingMode = TrackingMode.notStarted;

  late DateTime _lastContinueTime;
  Duration _lastStopDuration = Duration.zero;
  Duration get _currentDuration => _trackingMode == TrackingMode.tracking
      ? _lastStopDuration + DateTime.now().difference(_lastContinueTime)
      : _lastStopDuration;

  String _locationInfo = "no data";
  String _stepInfo = "no data";
  String _heartRateInfo = "no data";

  late Timer _timer;
  late LocationUtils _locationUtils;

  late StepCountUtils _stepUtils;

  HeartRateUtils? _heartRateUtils;

  late MapboxMapController _mapController;
  late Line _line;
  List<Circle> _circles = [];

  @override
  void initState() {
    _cardioSessionDescription = CardioSessionDescription(
      cardioSession: CardioSession.defaultValue(widget.movement.id)
        ..cardioType = widget.cardioType
        ..time = Duration.zero
        ..distance = 0
        ..track = []
        ..cadence = []
        ..heartRate = widget.heartRateMonitorId != null ? [] : null
        ..routeId = widget.route?.id,
      movement: widget.movement,
      route: widget.route,
    );
    _locationUtils = LocationUtils(_onLocationUpdate);
    _stepUtils = StepCountUtils(_onStepCountUpdate);
    if (widget.heartRateMonitorId != null) {
      _heartRateUtils = HeartRateUtils(
        deviceId: widget.heartRateMonitorId!,
        onHeartRateEvent: _onHeartRateUpdate,
      );
    }
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateData());
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    _stepUtils.stopStepCountStream();
    _locationUtils.stopLocationStream();
    _heartRateUtils?.stopHeartRateStream();
    if (_mapController.cameraPosition != null) {
      Settings.lastMapPosition = _mapController.cameraPosition!;
    }
    if (_locationUtils.lastLatLng != null) {
      Settings.lastGpsLatLng = _locationUtils.lastLatLng!;
    }
    super.dispose();
  }

  Future<void> _saveCardioSession() async {
    _cardioSessionDescription.cardioSession.time = _currentDuration;
    _cardioSessionDescription.cardioSession.setEmptyListsToNull();
    _cardioSessionDescription.cardioSession.setAscentDescent();
    _cardioSessionDescription.cardioSession.setAvgCadence();
    _cardioSessionDescription.cardioSession.setAvgHeartRate();
    _cardioSessionDescription.cardioSession.setDistance();
    final result = await _dataProvider.createSingle(_cardioSessionDescription);
    if (result.isSuccess()) {
      Navigator.pop(context); // pop dialog
      Navigator.pop(context); // pop tracking page
      Navigator.pop(context); // pop tracking settings page
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Cardio Session failed:\n${result.failure}',
      );
    }
  }

  void _updateData() {
    // called every second
    setState(() {
      if (_trackingMode == TrackingMode.tracking) {
        _cardioSessionDescription.cardioSession.time = _currentDuration;
      }
      _cardioSessionDescription.cardioSession.setAscentDescent();
      _cardioSessionDescription.cardioSession.setAvgCadence();
      _cardioSessionDescription.cardioSession.setAvgHeartRate();
      _cardioSessionDescription.cardioSession.setDistance();
    });
  }

  Future<void> _startStreams() async {
    await _locationUtils.startLocationStream();
    await _stepUtils.startStepCountStream();
    _heartRateUtils?.startHeartRateStream();
  }

  void _onHeartRateUpdate(PolarHeartRateEvent event) {
    _logger.i('rr: ${event.data.rrsMs}');

    if (_trackingMode == TrackingMode.tracking) {
      if (_cardioSessionDescription.cardioSession.heartRate!.isEmpty &&
          event.data.rrsMs.isNotEmpty) {
        _cardioSessionDescription.cardioSession.heartRate!
            .add(_currentDuration);
      } else {
        for (final rr in event.data.rrsMs) {
          _cardioSessionDescription.cardioSession.heartRate!.add(
            _cardioSessionDescription.cardioSession.heartRate!.last +
                Duration(milliseconds: rr),
          );
        }
      }
    }
    _heartRateInfo = "rr: ${event.data.rrsMs} ms\nhr: ${event.data.hr} bpm";
  }

  void _onStepCountUpdate(StepCount stepCount) {
    if (_trackingMode == TrackingMode.tracking) {
      if (_cardioSessionDescription.cardioSession.cadence!.isEmpty) {
        _cardioSessionDescription.cardioSession.cadence!.add(
          stepCount.timeStamp
              .difference(_cardioSessionDescription.cardioSession.datetime),
        );
      } else {
        /// interpolate steps since last stepCount update
        int newSteps = stepCount.steps - _stepUtils.lastStepCount.steps;
        double avgTimeDiff = stepCount.timeStamp
                .difference(_stepUtils.lastStepCount.timeStamp)
                .inMilliseconds /
            newSteps;
        for (int i = 1; i <= newSteps; i++) {
          _cardioSessionDescription.cardioSession.cadence!.add(
            _cardioSessionDescription.cardioSession.cadence!.last +
                Duration(milliseconds: (avgTimeDiff * i).round()),
          );
        }
      }
    }
    _stepInfo =
        "step count: ${stepCount.steps}\ntimestamp: ${stepCount.timeStamp.formatTimeHms}";
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    _locationInfo = """provider:   ${location.provider}
accuracy: ${location.accuracy?.toInt()} m
time: ${location.time! ~/ 1000} s
satelites:  ${location.satelliteNumber}
points:      ${_cardioSessionDescription.cardioSession.track?.length}""";

    await _mapController.animateCamera(
      CameraUpdate.newLatLng(location.latLng),
    );

    _circles = await _mapController.updateCurrentLocationMarker(
      _circles,
      location.latLng,
    );

    if (_trackingMode == TrackingMode.tracking) {
      _cardioSessionDescription.cardioSession.track!.add(
        Position(
          latitude: location.latitude!,
          longitude: location.longitude!,
          elevation: location.altitude!,
          distance: _cardioSessionDescription.cardioSession.track!.isEmpty
              ? 0
              : _cardioSessionDescription.cardioSession.track!.last
                  .addDistanceTo(location.latitude!, location.longitude!),
          time: _currentDuration,
        ),
      );
      await _mapController.updateTrackLine(
        _line,
        _cardioSessionDescription.cardioSession.track!,
      );
    }
  }

  Future<void> _stopDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Recording"),
        content: TextField(
          onSubmitted: (comments) => setState(
            () => _cardioSessionDescription.cardioSession.comments = comments,
          ),
          decoration: const InputDecoration(hintText: "Comments"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: _cardioSessionDescription.isValidBeforeSanitazion()
                ? () async {
                    _trackingMode = TrackingMode.stopped;
                    await _saveCardioSession();
                  }
                : null,
          )
        ],
      ),
    );
  }

  // ignore: long-method
  List<Widget> _buildButtons() {
    switch (_trackingMode) {
      case TrackingMode.tracking:
        return [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                _trackingMode = TrackingMode.paused;
                _lastStopDuration +=
                    DateTime.now().difference(_lastContinueTime);
              },
              child: const Text("pause"),
            ),
          ),
          Defaults.sizedBox.horizontal.normal,
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                _trackingMode = TrackingMode.paused;
                _lastStopDuration +=
                    DateTime.now().difference(_lastContinueTime);
                await _stopDialog();
              },
              child: const Text("stop"),
            ),
          ),
        ];
      case TrackingMode.paused:
        return [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.errorContainer,
              ),
              onPressed: () {
                _trackingMode = TrackingMode.tracking;
                _lastContinueTime = DateTime.now();
              },
              child: const Text("continue"),
            ),
          ),
          Defaults.sizedBox.horizontal.normal,
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                _trackingMode = TrackingMode.paused;
                await _stopDialog();
              },
              child: const Text("stop"),
            ),
          ),
        ];
      default:
        return [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.errorContainer,
              ),
              onPressed: _heartRateUtils == null || _heartRateUtils!.active
                  ? () {
                      _trackingMode = TrackingMode.tracking;
                      _cardioSessionDescription.cardioSession.datetime =
                          DateTime.now();
                      _lastContinueTime =
                          _cardioSessionDescription.cardioSession.datetime;
                    }
                  : null,
              child: Text(
                _heartRateUtils == null || _heartRateUtils!.active
                    ? "start"
                    : "waiting on HR Monitor",
              ),
            ),
          ),
          Defaults.sizedBox.horizontal.normal,
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("cancel"),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 25, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_locationInfo),
                Text(_stepInfo),
                Text(_heartRateInfo),
              ],
            ),
          ),
          Expanded(
            child: MapboxMap(
              accessToken: Config.instance.accessToken,
              styleString: Defaults.mapbox.style.outdoor,
              initialCameraPosition: CameraPosition(
                zoom: 15.0,
                target: Settings.lastGpsLatLng,
              ),
              trackCameraPosition: true,
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.TopRight,
              onMapCreated: (MapboxMapController controller) =>
                  _mapController = controller,
              onStyleLoadedCallback: () async {
                if (_cardioSessionDescription.route?.track != null) {
                  await _mapController.addRouteLine(
                    _cardioSessionDescription.route!.track!,
                  );
                }
                _line = await _mapController.addTrackLine(
                  _cardioSessionDescription.cardioSession.track!,
                ); // init with empty track
                await _startStreams();
              },
            ),
          ),
          Container(
            padding: Defaults.edgeInsets.normal,
            child: Column(
              children: [
                CardioValueUnitDescriptionTable(
                  cardioSessionDescription: _cardioSessionDescription,
                ),
                Defaults.sizedBox.vertical.normal,
                Row(children: _buildButtons()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
