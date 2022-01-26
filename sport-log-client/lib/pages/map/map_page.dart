import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final _logger = Logger('MapPage');

  late MapboxMapController _sessionMapController;
  bool overlaysVisible = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      _logger.i("overlays $systemOverlaysAreVisible");
      overlaysVisible = systemOverlaysAreVisible;
    }); // TODO

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          //overlaysVisible ?
          AppBar(
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
      ),
      //: null,
      drawer: const MainDrawer(selectedRoute: Routes.map),
      body: MapboxMap(
        accessToken: Defaults.mapbox.accessToken,
        styleString: Defaults.mapbox.style.outdoor,
        initialCameraPosition: const CameraPosition(
          zoom: 13.0,
          target: LatLng(47.27, 11.33),
        ),
        onMapCreated: (MapboxMapController controller) =>
            _sessionMapController = controller,
      ),
    );
  }

  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
