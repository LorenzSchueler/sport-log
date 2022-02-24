import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
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
  //bool showMapSettings = false;

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
            initialCameraPosition: CameraPosition(
              zoom: 13.0,
              target: Defaults.mapbox.cameraPosition,
            ),
            onMapCreated: (MapboxMapController controller) =>
                _sessionMapController = controller,
            onMapClick: (_, __) => setState(() {
              showOverlays = !showOverlays;
              //showMapSettings = false;
            }),
          ),
          //if (showMapSettings)
          //Positioned(
          //bottom: 0,
          //child: SizedBox.expand(
          //child: Container(
          //width: double.infinity,
          //height: 100,
          //color: Colors.white,
          //child: Row(children: [
          //IconButton(
          //onPressed: () => setState(() {
          //mapStyle = Defaults.mapbox.style.outdoor;
          //}),
          //icon: const Icon(AppIcons.map),
          //),
          //IconButton(
          //onPressed: () => setState(() {
          //mapStyle = Defaults.mapbox.style.street;
          //}),
          //icon: const Icon(AppIcons.map),
          //),
          //IconButton(
          //onPressed: () => setState(() {
          //mapStyle = Defaults.mapbox.style.satellite;
          //}),
          //icon: const Icon(AppIcons.map),
          //)
          //])))),
          if (showOverlays)
            Positioned(
                top: 5,
                right: 5,
                child:
                    //IconButton(
                    //icon: const Icon(AppIcons.map),
                    //color: Theme.of(context).colorScheme.primary,
                    //onPressed: () => setState(() {
                    //showMapSettings = !showMapSettings;
                    //_logger.i("map settings: $showMapSettings");
                    //}),
                    //)
                    ExpandableFab(
                        horizontal: true,
                        icon: const Icon(AppIcons.map),
                        buttons: [
                      ActionButton(
                          icon: const Icon(AppIcons.map),
                          onPressed: () => setState(() {
                                mapStyle = Defaults.mapbox.style.outdoor;
                              })),
                      ActionButton(
                          icon: const Icon(AppIcons.map),
                          onPressed: () => setState(() {
                                mapStyle = Defaults.mapbox.style.street;
                              })),
                      ActionButton(
                          icon: const Icon(AppIcons.map),
                          onPressed: () => setState(() {
                                mapStyle = Defaults.mapbox.style.satellite;
                              })),
                    ]))
        ]));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
