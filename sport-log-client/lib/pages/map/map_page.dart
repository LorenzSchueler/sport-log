import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final _logger = Logger('MapPage');

  late MapboxMapController _sessionMapController;
  bool showOverlays = true;

  String mapStyle = Defaults.mapbox.style.outdoor;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: showOverlays
            ? AppBar(
                backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                elevation: 0,
              )
            : null,
        drawer: const MainDrawer(selectedRoute: Routes.map),
        body: Stack(children: [
          MapboxMap(
            accessToken: Defaults.mapbox.accessToken,
            styleString: mapStyle,
            initialCameraPosition: const CameraPosition(
              zoom: 13.0,
              target: LatLng(47.27, 11.33),
            ),
            onMapCreated: (MapboxMapController controller) =>
                _sessionMapController = controller,
            onMapClick: (_, __) => setState(() {
              showOverlays = !showOverlays;
            }),
          ),
          if (showOverlays)
            Positioned(
                top: 5,
                right: 5,
                child: ExpandableFab(
                    horizontal: true,
                    icon: const Icon(Icons.map),
                    items: [
                      ExpandableFabItem(
                          icon: const Icon(Icons.map),
                          onPressed: () => setState(() {
                                mapStyle = Defaults.mapbox.style.outdoor;
                              })),
                      ExpandableFabItem(
                          icon: const Icon(Icons.map),
                          onPressed: () => setState(() {
                                mapStyle = Defaults.mapbox.style.street;
                              })),
                      ExpandableFabItem(
                          // TODO does not react
                          icon: const Icon(Icons.map),
                          onPressed: () => setState(() {
                                mapStyle = Defaults.mapbox.style.satellite;
                              })),
                    ])),
        ]));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
