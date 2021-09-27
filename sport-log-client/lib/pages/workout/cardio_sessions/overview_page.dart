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

  @override
  Widget build(BuildContext context) {
    return MapScreen();
  }

  void onFabTapped(BuildContext context) {
    _logger.d('FAB tapped!');
  }
}

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String token = Secrets.mapboxAccessToken;
    final String style = 'mapbox://styles/mapbox/outdoors-v11';

    return Scaffold(
      body: MapboxMap(
        accessToken: token,
        styleString: style,
        initialCameraPosition: CameraPosition(
          zoom: 12.0,
          target: LatLng(47.27, 11.33),
        ),
        compassEnabled: true,
      ),
    );
  }
}
