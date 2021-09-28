import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');
  final String token = Secrets.mapboxAccessToken;
  final String style = 'mapbox://styles/mapbox/outdoors-v11';
  late MapboxMapController mapController;

  void addSymbol(MapboxMapController controller) async {
    var location = await acquireCurrentLocation();
    //var location = LatLng(47.28, 11.33);

    await controller.animateCamera(
      CameraUpdate.newLatLng(location),
    );

    await controller.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#006992',
        circleOpacity: 0.8,
        geometry: location,
        draggable: false,
      ),
    );

    await controller.addLine(const LineOptions(
        lineColor: "red",
        lineBlur: 1.0,
        lineWidth: 5,
        geometry: [
          LatLng(47.28, 11.33),
          LatLng(47.29, 11.33),
          LatLng(47.29, 11.34)
        ]));
    await controller.addSymbol(const SymbolOptions(
        iconImage: "town-hall-15", geometry: LatLng(47.29, 11.34)));
  }

  void markLocation(MapboxMapController controller, LatLng location) async {
    await controller.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#006992',
        circleOpacity: 0.8,
        geometry: location,
        draggable: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapboxMap(
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
        onStyleLoadedCallback: () => addSymbol(mapController),
        onMapLongClick: (point, LatLng coordinates) =>
            markLocation(mapController, coordinates),
        onUserLocationUpdated: (UserLocation location) {
          print(location.altitude);
          print(location.position.latitude);
          print(location.position.longitude);
        },
      ),
    );
    ;
  }

  void onFabTapped(BuildContext context) {
    _logger.d('FAB tapped!');
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
