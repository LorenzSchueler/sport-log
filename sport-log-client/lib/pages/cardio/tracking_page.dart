import 'package:fixnum/fixnum.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/movement_picker.dart';

enum TrackingMode { notStarted, tracking, paused, stopped }

class CardioTrackingPage extends StatefulWidget {
  const CardioTrackingPage({Key? key}) : super(key: key);

  @override
  State<CardioTrackingPage> createState() => CardioTrackingPageState();
}

class CardioTrackingPageState extends State<CardioTrackingPage> {
  final _logger = Logger('CardioTrackingPage');

  final String _token = Secrets.mapboxAccessToken;
  final String _style = 'mapbox://styles/mapbox/outdoors-v11';

  final List<Position> _positions = [];
  late DateTime startTime;
  late DateTime pauseStopTime;
  int seconds = 0;
  late Movement movement;

  Line? _line;
  List<Circle>? _circles;

  TrackingMode _trackingMode = TrackingMode.notStarted;

  String _locationInfo = "";

  late MapboxMapController _mapController;

  void _saveCardioSession() {
    CardioSession(
      id: randomId(),
      userId: UserState.instance.currentUser!.id,
      movementId: Int64(1), //TODO
      cardioType: CardioType.training, //TODO
      datetime: startTime,
      distance: 0, //TODO
      ascent: null, //TODO
      descent: null, //TODO
      time: seconds,
      calories: null,
      track: _positions,
      avgCadence: null, //TODO
      cadence: null, //TODO
      avgHeartRate: null,
      heartRate: null,
      routeId: null,
      comments: null, //TODO
      deleted: false,
    );
  }

  Future<LatLng?> _startLocationStream() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    location.changeSettings(accuracy: LocationAccuracy.high);

    location.enableBackgroundMode(enable: true);
    location.onLocationChanged.listen(
        (LocationData currentLocation) => _locationConsumer(currentLocation));
  }

  void _locationConsumer(LocationData location) async {
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

  List<Widget> _buildButtons() {
    if (_trackingMode == TrackingMode.tracking) {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () {
                  setState(() {
                    _trackingMode = TrackingMode.paused;
                  });
                  seconds += DateTime.now().difference(pauseStopTime).inSeconds;
                },
                child: const Text("pause"))),
        const SizedBox(
          width: 10,
        ),
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () {
                  setState(() {
                    _trackingMode = TrackingMode.stopped;
                  });
                  _saveCardioSession();
                },
                child: const Text("stop"))),
      ];
    } else if (_trackingMode == TrackingMode.paused) {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                onPressed: () {
                  setState(() {
                    _trackingMode = TrackingMode.tracking;
                  });
                  pauseStopTime = DateTime.now();
                },
                child: const Text("continue"))),
        const SizedBox(
          width: 10,
        ),
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () {
                  setState(() {
                    _trackingMode = TrackingMode.stopped;
                  });
                  _saveCardioSession();
                  seconds += DateTime.now().difference(pauseStopTime).inSeconds;
                },
                child: const Text("stop"))),
      ];
    } else {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                onPressed: () {
                  setState(() {
                    _trackingMode = TrackingMode.tracking;
                  });
                  startTime = DateTime.now();
                  pauseStopTime = DateTime.now();
                },
                child: const Text("start"))),
        const SizedBox(
          width: 10,
        ),
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
      Card(
          margin: const EdgeInsets.only(top: 25, bottom: 5),
          child: Text(_locationInfo)),
      Expanded(
          child: MapboxMap(
        accessToken: _token,
        styleString: _style,
        initialCameraPosition: const CameraPosition(
          zoom: 14.0,
          target: LatLng(47.27, 11.33),
        ),
        compassEnabled: true,
        compassViewPosition: CompassViewPosition.TopRight,
        onMapCreated: (MapboxMapController controller) =>
            _mapController = controller,
        onStyleLoadedCallback: () => _startLocationStream(),
      )),
      Container(
          padding: const EdgeInsets.only(top: 5),
          color: onPrimaryColorOf(context),
          child: Table(
            children: [
              TableRow(children: [
                _buildCard("00:31:15", "time"),
                _buildCard("6.17 km", "distance"),
              ]),
              TableRow(children: [
                _buildCard("10.7 km/h", "speed"),
                _buildCard("163", "step rate"),
              ]),
              TableRow(children: [
                _buildCard("231 m", "ascent"),
                _buildCard("51 m", "descent"),
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
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      movement = await showMovementPickerDialog(context,
          dismissable: false, cardioOnly: true) as Movement;
    });
  }
}
