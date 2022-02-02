import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/theme.dart';
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

  String mapStyle = Defaults.mapbox.style.outdoor;
  bool showMapStyleButtons = true;

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
          ),
          showMapStyleButtons // TODO
              ? Positioned(
                  top: 10,
                  right: 5,
                  child: Container(
                    //height: 50,
                    //width: 200,

                    width: 50,
                    height: 200,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(150, 0, 0, 0),
                        borderRadius: Defaults.borderRadius.normal),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                //padding: EdgeInsets.all(0),
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                _logger.i("hide map style buttons");
                                setState(() {
                                  showMapStyleButtons = false;
                                  mapStyle = Defaults.mapbox.style.outdoor;
                                });
                              },
                              child: const Icon(Icons.map)),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                _logger.i("hide map style buttons");
                                setState(() {
                                  showMapStyleButtons = false;
                                  mapStyle = Defaults.mapbox.style.satellite;
                                });
                              },
                              child: const Icon(Icons.map)),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                _logger.i("hide map style buttons");
                                setState(() {
                                  showMapStyleButtons = false;
                                  mapStyle = Defaults.mapbox.style.street;
                                });
                              },
                              child: const Icon(Icons.map)),
                        ]),
                  ))
              : Positioned(
                  top: 10,
                  right: 5,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                      ),
                      onPressed: () => setState(() {
                            _logger.i("show map style buttons");
                            showMapStyleButtons = true;
                          }),
                      child: const Icon(Icons.map)),
                ),
        ]));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
