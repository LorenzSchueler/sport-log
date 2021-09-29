import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';

class CardioTrackingPage extends StatefulWidget {
  const CardioTrackingPage({Key? key}) : super(key: key);

  @override
  State<CardioTrackingPage> createState() => CardioTrackingPageState();
}

class CardioTrackingPageState extends State<CardioTrackingPage> {
  final _logger = Logger('CardioTrackingPage');

  final String token = Secrets.mapboxAccessToken;
  final String style = 'mapbox://styles/mapbox/outdoors-v11';

  List<LatLng> locations = [];
  late Line line;
  LineOptions lineoptions =
      const LineOptions(lineColor: "red", lineWidth: 3, geometry: []);

  late MapboxMapController mapController;

  void init(MapboxMapController controller) async {
    await controller.addLine(lineoptions);
    line = controller.lines.first;

    var location = await acquireCurrentLocation();
    //var location = LatLng(47.28, 11.33);

    await controller.animateCamera(
      CameraUpdate.newLatLng(location),
    );

    await controller.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#0060a0',
        circleOpacity: 0.8,
        geometry: location,
        draggable: false,
      ),
    );

    //await controller.addSymbol(const SymbolOptions(
    //iconImage: "town-hall-15", geometry: LatLng(47.29, 11.34)));

    _logger.i("requesting location");
    var x = await controller.requestMyLocationLatLng();
    _logger.i("requested location: ${x}");
  }

  void markPosition(MapboxMapController controller, LatLng location) async {
    await controller.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#008080',
        circleOpacity: 0.8,
        geometry: location,
        draggable: false,
      ),
    );
  }

  void extendLine(MapboxMapController controller, LatLng location) async {
    locations.add(location);
    await controller.updateLine(line, LineOptions(geometry: locations));
  }

  Widget _buildCard(String title, String subtitle) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(0, 2, 0, 0),
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: MapboxMap(
        accessToken: token,
        styleString: style,
        initialCameraPosition: const CameraPosition(
          zoom: 12.0,
          target: LatLng(47.27, 11.33),
        ),
        compassEnabled: true,
        compassViewPosition: CompassViewPosition.TopRight,
        myLocationEnabled: true,
        myLocationRenderMode: MyLocationRenderMode.GPS,
        myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
        onMapCreated: (MapboxMapController controller) =>
            mapController = controller,
        onStyleLoadedCallback: () => init(mapController),
        onMapClick: (point, LatLng coordinates) =>
            markPosition(mapController, coordinates),
        onMapLongClick: (point, LatLng coordinates) =>
            extendLine(mapController, coordinates),
        onUserLocationUpdated: (UserLocation location) {
          _logger.i(
              "position ${location.position}; elevation ${location.altitude}");
        },
      )),
      Container(
          padding: const EdgeInsets.all(5),
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
            children: [
              Expanded(
                  child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(primary: Colors.green[400]),
                      onPressed: null,
                      child: const Text("start"))),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("cancel"))),
            ],
          ))
    ]);
  }
}

Future<LatLng?> acquireCurrentLocation() async {
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

  //location.enableBackgroundMode(enable: true);
  //location.onLocationChanged.listen((LocationData currentLocation) {});

  final locationData = await location.getLocation();
  return LatLng(locationData.latitude, locationData.longitude);
}
