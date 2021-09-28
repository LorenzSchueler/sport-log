import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/ui_cubit.dart';

import '../../../routes.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');

  final String token = Secrets.mapboxAccessToken;
  final String style = 'mapbox://styles/mapbox/outdoors-v11';

  @override
  void initState() {
    context.read<SessionsUiCubit>().showFab();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            children: <Widget>[
          _buildSessionCard(),
          _buildSessionCard(),
          _buildSessionCard(),
          _buildSessionCard(),
          _buildSessionCard()
        ]));
    ;
  }

  Widget _buildSessionCard() {
    late MapboxMapController _sessionMapController;
    var _locations = [
      LatLng(47.27, 11.33),
      LatLng(47.27, 11.331),
      LatLng(47.271, 11.33),
      LatLng(47.271, 11.331)
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(5),
      color: onPrimaryColorOf(context),
      child: Column(children: [
        SizedBox(
            height: 150,
            child: MapboxMap(
              accessToken: token,
              styleString: style,
              initialCameraPosition: const CameraPosition(
                zoom: 13.0,
                target: LatLng(47.27, 11.33),
              ),
              onMapCreated: (MapboxMapController controller) =>
                  _sessionMapController = controller,
              onStyleLoadedCallback: () => _sessionMapController
                  .addLine(LineOptions(lineColor: "red", geometry: _locations)),
            )),
        const SizedBox(
          height: 5,
        ),
        Row(children: [
          Expanded(
              child: Text(
            "1:41:53",
            textAlign: TextAlign.center,
          )),
          Expanded(
              child: Text(
            "18.54 km",
            textAlign: TextAlign.center,
          )),
          Expanded(
              child: Text(
            "11.3 km/h",
            textAlign: TextAlign.center,
          ))
        ]),
      ]),
    );
  }

  void onFabTapped(BuildContext context) {
    _logger.d('FAB tapped!');
    Navigator.of(context).pushNamed(Routes.cardio.tracking);
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 250,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(vertical: 5),
        color: onPrimaryColorOf(context),
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
        ));
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
