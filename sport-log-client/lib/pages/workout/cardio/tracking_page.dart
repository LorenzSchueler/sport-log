import 'dart:async';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/map_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

enum TrackingMode { notStarted, tracking, paused, stopped }

class CardioTrackingPage extends StatefulWidget {
  final Movement movement;
  final CardioType cardioType;
  final Route? route;

  const CardioTrackingPage({
    required this.route,
    required this.movement,
    required this.cardioType,
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
  double _ascent = 0;
  double _descent = 0;
  double? _lastElevation;

  String _locationInfo = "null";
  String _stepInfo = "null";

  late Timer _timer;
  late LocationUtils _locationUtils;

  late StreamSubscription _stepCountSubscription;
  late StepCount _lastStepCount;

  late MapboxMapController _mapController;
  late Line _line;
  List<Circle> _circles = [];

  @override
  void initState() {
    _cardioSessionDescription = CardioSessionDescription(
      cardioSession: CardioSession.defaultValue(widget.movement.id)
        ..cardioType = widget.cardioType
        ..time = Duration.zero
        ..distance = 1 // TODO remove when distance calculated from track
        ..track = []
        ..cadence = []
        ..routeId = widget.route?.id,
      movement: widget.movement,
      route: widget.route,
    );
    _locationUtils = LocationUtils(_onLocationUpdate);
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateData());
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    _stepCountSubscription.cancel();
    _locationUtils.stopLocationStream();
    if (_mapController.cameraPosition != null) {
      Settings.lastMapPosition = _mapController.cameraPosition!;
    }
    if (_cardioSessionDescription.cardioSession.track != null &&
        _cardioSessionDescription.cardioSession.track!.isNotEmpty) {
      Settings.lastGpsLatLng =
          _cardioSessionDescription.cardioSession.track!.last.latLng;
    }
    super.dispose();
  }

  Future<void> _saveCardioSession() async {
    _cardioSessionDescription.setEmptyToNull();
    _cardioSessionDescription.cardioSession.ascent = _ascent.round();
    _cardioSessionDescription.cardioSession.descent = _descent.round();
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
        _cardioSessionDescription.cardioSession.time =
            _cardioSessionDescription.cardioSession.time! +
                const Duration(seconds: 1);
      }
      _cardioSessionDescription.cardioSession.setAvgCadence();
      _cardioSessionDescription.cardioSession.setAvgHeartRate();
      //_cardioSessionDescription.cardioSession.setDistance();

      if (_cardioSessionDescription.cardioSession.cadence != null) {
        _stepInfo =
            "steps: ${_cardioSessionDescription.cardioSession.cadence!.length}\ntime: ${_cardioSessionDescription.cardioSession.cadence!.isNotEmpty ? _cardioSessionDescription.cardioSession.cadence!.last : 0}";
      }
    });
  }

  void _startStepCountStream() {
    Stream<StepCount> _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream.listen(_onStepCountUpdate);
    // ignore: unnecessary_lambdas
    _stepCountSubscription.onError((dynamic error) => _logger.i(error));
  }

  void _onStepCountUpdate(StepCount stepCountEvent) {
    if (_trackingMode == TrackingMode.tracking) {
      if (_cardioSessionDescription.cardioSession.cadence!.isEmpty) {
        _cardioSessionDescription.cardioSession.cadence!.add(
          stepCountEvent.timeStamp
              .difference(_cardioSessionDescription.cardioSession.datetime),
        );
      } else {
        /// interpolate steps since last stepCount update
        int newSteps = stepCountEvent.steps - _lastStepCount.steps;
        double avgTimeDiff = stepCountEvent.timeStamp
                .difference(_lastStepCount.timeStamp)
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
    _cardioSessionDescription.cardioSession.setAvgCadence();
    _lastStepCount = stepCountEvent;
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    setState(() {
      _locationInfo = """provider:  ${location.provider}
accuracy: ${location.accuracy?.toInt()} m
time: ${location.time! ~/ 1000} s
satelites:  ${location.satelliteNumber}""";
    });

    LatLng latLng = LatLng(location.latitude!, location.longitude!);

    await _mapController.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );

    _circles =
        await _mapController.updateCurrentLocationMarker(_circles, latLng);

    if (_trackingMode == TrackingMode.tracking) {
      _lastElevation ??= location.altitude;
      double elevationDifference = location.altitude! - _lastElevation!;
      setState(() {
        if (elevationDifference > 0) {
          _ascent += elevationDifference;
        } else {
          _descent -= elevationDifference;
        }
      });
      _lastElevation = location.altitude;

      _cardioSessionDescription.cardioSession.track!.add(
        Position(
          latitude: location.latitude!,
          longitude: location.longitude!,
          elevation: location.altitude!,
          distance: 0,
          time: _cardioSessionDescription.cardioSession.time!,
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
            onPressed: _cardioSessionDescription.isValidIgnoreEmptyNotNull()
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

  List<Widget> _buildButtons() {
    if (_trackingMode == TrackingMode.tracking) {
      return [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              _trackingMode = TrackingMode.paused;
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
              await _stopDialog();
            },
            child: const Text("stop"),
          ),
        ),
      ];
    } else if (_trackingMode == TrackingMode.paused) {
      return [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Theme.of(context).colorScheme.errorContainer,
            ),
            onPressed: () => _trackingMode = TrackingMode.tracking,
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
    } else {
      return [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Theme.of(context).colorScheme.errorContainer,
            ),
            onPressed: () {
              _trackingMode = TrackingMode.tracking;
              _cardioSessionDescription.cardioSession.datetime = DateTime.now();
            },
            child: const Text("start"),
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
    TableRow rowSpacer = TableRow(
      children: [
        Defaults.sizedBox.vertical.normal,
        Defaults.sizedBox.vertical.normal,
      ],
    );

    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Card(
                margin: const EdgeInsets.only(top: 25, bottom: 5),
                child: Text(_locationInfo),
              ),
              Card(
                margin: const EdgeInsets.only(top: 25, bottom: 5),
                child: Text(_stepInfo),
              ),
            ],
          ),
          Expanded(
            child: MapboxMap(
              accessToken: Defaults.mapbox.accessToken,
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
                await _locationUtils.startLocationStream();
                _startStepCountStream();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10),
            child: Table(
              children: [
                TableRow(
                  children: [
                    ValueUnitDescription(
                      value: _cardioSessionDescription
                          .cardioSession.time!.formatTime,
                      unit: null,
                      description: "time",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: _cardioSessionDescription.cardioSession.distance ==
                              null
                          ? "--"
                          : (_cardioSessionDescription.cardioSession.distance! /
                                  1000)
                              .toStringAsFixed(3),
                      unit: "km",
                      description: "distance",
                      scale: 1.3,
                    ),
                  ],
                ),
                rowSpacer,
                TableRow(
                  children: [
                    const ValueUnitDescription(
                      value: "--",
                      unit: "km/h",
                      description: "speed",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value:
                          "${_cardioSessionDescription.cardioSession.avgCadence}",
                      unit: "rpm",
                      description: "cadence",
                      scale: 1.3,
                    ),
                  ],
                ),
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription(
                      value: _ascent.round().toString(),
                      unit: "m",
                      description: "ascent",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: _descent.round().toString(),
                      unit: "m",
                      description: "descent",
                      scale: 1.3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: Defaults.edgeInsets.normal,
            child: Row(
              children: _buildButtons(),
            ),
          )
        ],
      ),
    );
  }
}
