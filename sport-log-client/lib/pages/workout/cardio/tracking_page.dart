import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'dart:async';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/movement_picker.dart';

enum TrackingMode { notStarted, tracking, paused, stopped }

class CardioTrackingPage extends StatefulWidget {
  final Movement _movement;
  final CardioType _cardioType;
  final Route? _route;

  const CardioTrackingPage(this._movement, this._cardioType, this._route,
      {Key? key})
      : super(key: key);

  @override
  State<CardioTrackingPage> createState() => CardioTrackingPageState();
}

class CardioTrackingPageState extends State<CardioTrackingPage> {
  final _logger = Logger('CardioTrackingPage');

  final String _token = Secrets.mapboxAccessToken;
  final String _style = 'mapbox://styles/mapbox/outdoors-v11';

  final List<Position> _positions = [];
  double _ascent = 0;
  double _descent = 0;
  double? _lastElevation;

  final List<double> _stepTimes = [];
  late StepCount _lastStepCount;
  int _stepRate = 0;

  late DateTime _startTime;
  DateTime? _pauseEndTime;
  int _seconds = 0;
  String _time = "00:00:00";

  String? _comments;

  Line? _line;
  List<Circle>? _circles;

  TrackingMode _trackingMode = TrackingMode.notStarted;

  String _locationInfo = "null";
  String _stepInfo = "null";

  late Timer _timer;
  StreamSubscription? _locationSubscription;
  late StreamSubscription _stepCountSubscription;
  late MapboxMapController _mapController;

  void _updateData() {
    Duration duration = _trackingMode == TrackingMode.tracking
        ? Duration(seconds: _seconds) +
            DateTime.now().difference(_pauseEndTime!)
        : Duration(seconds: _seconds);
    setState(() {
      _time = duration.toString().split('.').first.padLeft(8, '0');

      _stepRate = duration.inSeconds > 0 && _stepTimes.isNotEmpty
          ? (_stepTimes.length / duration.inSeconds * 60).round()
          : 0;
      _stepInfo =
          "steps: ${_stepTimes.length}\ntime: ${_stepTimes.isNotEmpty ? _stepTimes.last : 0}\nstep rate: $_stepRate";
    });
    _logger.i(_stepInfo);
  }

  void _saveCardioSession() {
    CardioSession(
      id: randomId(),
      userId: UserState.instance.currentUser!.id,
      movementId: widget._movement.id,
      cardioType: widget._cardioType,
      datetime: _startTime,
      distance: 0, //TODO
      ascent: _ascent.round(),
      descent: _descent.round(),
      time: _seconds,
      calories: null,
      track: _positions,
      avgCadence: (_stepTimes.length / _seconds * 60).round(),
      cadence: _stepTimes,
      avgHeartRate: null,
      heartRate: null,
      routeId: widget._route?.id,
      comments: _comments,
      deleted: false,
    );
    // TODO save in db
  }

  void _onStepCountUpdate(StepCount stepCountEvent) {
    if (_trackingMode == TrackingMode.tracking) {
      if (_stepTimes.isEmpty) {
        _stepTimes.add(stepCountEvent.timeStamp.millisecondsSinceEpoch / 1000);
      } else {
        /// interpolate steps since last stepCount update
        int newSteps = stepCountEvent.steps - _lastStepCount.steps;
        double avgTimeDiff = (stepCountEvent.timeStamp.millisecondsSinceEpoch -
                _lastStepCount.timeStamp.millisecondsSinceEpoch) /
            newSteps;
        for (int i = 1; i <= newSteps; i++) {
          _stepTimes.add(_stepTimes.last + avgTimeDiff * i / 1000);
        }
      }
    }
    _lastStepCount = stepCountEvent;
  }

  void _onStepCountError(Object error) {
    _logger.i(error);
  }

  void _startStepCountStream() {
    Stream<StepCount> _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream.listen(_onStepCountUpdate);
    _stepCountSubscription.onError(_onStepCountError);
  }

  void _startLocationStream() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.changeSettings(accuracy: LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
    _locationSubscription =
        location.onLocationChanged.listen(_onLocationUpdate);
  }

  void _onLocationUpdate(LocationData location) async {
    setState(() {
      _locationInfo = """location provider: ${location.provider}
accuracy: ${location.accuracy?.toInt()} m
time: ${location.time! ~/ 1000} s
satelites: ${location.satelliteNumber}""";
    });

    _logger.i(_locationInfo);

    LatLng latLng = LatLng(location.latitude, location.longitude);

    await _mapController.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );

    if (_circles != null) {
      await _mapController.removeCircles(_circles);
    }
    _circles = await _mapController.addCircles([
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#0060a0',
        circleOpacity: 0.5,
        geometry: latLng,
        draggable: false,
      ),
      CircleOptions(
        circleRadius: 20.0,
        circleColor: '#0060a0',
        circleOpacity: 0.3,
        geometry: latLng,
        draggable: false,
      ),
    ]);

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

      _positions.add(Position(
          latitude: location.latitude!,
          longitude: location.longitude!,
          elevation: location.altitude!.toInt(),
          distance: 0,
          time: DateTime.now()
              .difference(
                  DateTime.fromMicrosecondsSinceEpoch(location.time!.toInt()))
              .inSeconds));
      _extendLine(_mapController, latLng);
    }
  }

  void _extendLine(MapboxMapController controller, LatLng location) async {
    _line ??= await controller.addLine(
        const LineOptions(lineColor: "red", lineWidth: 3, geometry: []));
    await controller.updateLine(
        _line,
        LineOptions(
            geometry: _positions
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList()));
  }

  Widget _buildCard(String title, String subtitle) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(top: 2),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25),
        ),
        subtitle: Text(
          subtitle,
          textAlign: TextAlign.center,
        ),
        dense: true,
      ),
    );
  }

  Future<void> _stopDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Recording"),
        content: TextField(
          onSubmitted: (comments) => _comments = comments,
          decoration: const InputDecoration(hintText: "Comments"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back")),
          TextButton(
              onPressed: () {
                _trackingMode = TrackingMode.stopped;
                _saveCardioSession();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  List<Widget> _buildButtons() {
    if (_trackingMode == TrackingMode.tracking) {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () {
                  _trackingMode = TrackingMode.paused;
                  _seconds +=
                      DateTime.now().difference(_pauseEndTime!).inSeconds;
                },
                child: const Text("pause"))),
        Defaults.sizedBox.horizontal.normal,
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () async {
                  _trackingMode = TrackingMode.paused;
                  _seconds +=
                      DateTime.now().difference(_pauseEndTime!).inSeconds;
                  await _stopDialog();
                },
                child: const Text("stop"))),
      ];
    } else if (_trackingMode == TrackingMode.paused) {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                onPressed: () {
                  _trackingMode = TrackingMode.tracking;
                  _pauseEndTime = DateTime.now();
                },
                child: const Text("continue"))),
        Defaults.sizedBox.horizontal.normal,
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () async {
                  await _stopDialog();
                },
                child: const Text("stop"))),
      ];
    } else {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                onPressed: () {
                  _trackingMode = TrackingMode.tracking;
                  _startTime = DateTime.now();
                  _pauseEndTime = DateTime.now();
                },
                child: const Text("start"))),
        Defaults.sizedBox.horizontal.normal,
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("cancel"))),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Card(
              margin: const EdgeInsets.only(top: 25, bottom: 5),
              child: Text(_locationInfo)),
          Card(
              margin: const EdgeInsets.only(top: 25, bottom: 5),
              child: Text(_stepInfo)),
        ],
      ),
      Expanded(
          child: MapboxMap(
        accessToken: _token,
        styleString: _style,
        initialCameraPosition: const CameraPosition(
          zoom: 15.0,
          target: LatLng(47.27, 11.33),
        ),
        compassEnabled: true,
        compassViewPosition: CompassViewPosition.TopRight,
        onMapCreated: (MapboxMapController controller) =>
            _mapController = controller,
        onStyleLoadedCallback: () {
          _startLocationStream();
          _startStepCountStream();
        },
      )),
      Container(
          padding: const EdgeInsets.only(top: 5),
          color: onPrimaryColorOf(context),
          child: Table(
            children: [
              TableRow(children: [
                _buildCard(_time, "time"),
                _buildCard("6.17 km", "distance"),
              ]),
              TableRow(children: [
                _buildCard("10.7 km/h", "speed"),
                _buildCard("$_stepRate", "step rate"),
              ]),
              TableRow(children: [
                _buildCard("${_ascent.round()} m", "ascent"),
                _buildCard("${_descent.round()} m", "descent"),
              ]),
            ],
          )),
      Container(
          color: onPrimaryColorOf(context),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: _buildButtons(),
          ))
    ]);
  }

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateData());
  }

  @override
  void dispose() {
    _timer.cancel();
    _locationSubscription?.cancel();
    _stepCountSubscription.cancel();
    super.dispose();
  }
}
