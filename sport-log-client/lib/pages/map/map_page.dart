import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
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
  bool showMapSettings = false;

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
      body: Stack(
        children: [
          MapboxMap(
            accessToken: Defaults.mapbox.accessToken,
            styleString: mapStyle,
            initialCameraPosition: CameraPosition(
              zoom: 13.0,
              target: Defaults.mapbox.cameraPosition,
            ),
            onMapCreated: (MapboxMapController controller) =>
                _sessionMapController = controller,
            onMapClick: (_, __) => setState(() {
              showOverlays = !showOverlays;
              showMapSettings = false;
            }),
          ),
          if (showMapSettings)
            Positioned(
              bottom: 0,
              left: 10,
              child: Container(
                width: MediaQuery.of(context).size.width - 20,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(AppIcons.map),
                      onPressed: () => setState(() {
                        mapStyle = Defaults.mapbox.style.outdoor;
                      }),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.car),
                      onPressed: () => setState(() {
                        mapStyle = Defaults.mapbox.style.street;
                      }),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.satellite),
                      onPressed: () => setState(() {
                        mapStyle = Defaults.mapbox.style.satellite;
                      }),
                    )
                  ],
                ),
              ),
            ),
          if (showOverlays)
            Positioned(
              top: 100,
              right: 15,
              child: FloatingActionButton.small(
                heroTag: null,
                child: const Icon(AppIcons.map),
                onPressed: () => setState(() {
                  showMapSettings = !showMapSettings;
                  _logger.i("map settings: $showMapSettings");
                }),
              ),
            )
        ],
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
