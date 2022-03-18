import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late LocationUtils _locationUtils;
  late MapboxMapController _mapController;
  bool showOverlays = true;
  bool showMapSettings = false;

  List<Circle>? _circles;
  LatLng? _lastLatLng;

  String mapStyle = Defaults.mapbox.style.outdoor;

  @override
  void initState() {
    _locationUtils = LocationUtils(_onLocationUpdate);
    super.initState();
  }

  @override
  void dispose() {
    _locationUtils.stopLocationStream();
    if (_mapController.cameraPosition != null) {
      Settings.lastMapPosition = _mapController.cameraPosition!;
    }
    if (_lastLatLng != null) {
      Settings.lastGpsLatLng = _lastLatLng!;
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _onLocationUpdate(geolocator.Position position) async {
    LatLng latLng = LatLng(position.latitude, position.longitude);

    await _mapController.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );
    if (_circles != null) {
      await _mapController.removeCircles(_circles!);
    }
    _circles = await _mapController.addCurrentLocationMarker(latLng);
  }

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
            initialCameraPosition: Settings.lastMapPosition,
            trackCameraPosition: true,
            onMapCreated: (MapboxMapController controller) =>
                _mapController = controller,
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
          if (showOverlays) ...[
            Positioned(
              top: 100,
              right: 15,
              child: FloatingActionButton.small(
                heroTag: null,
                child: const Icon(AppIcons.map),
                onPressed: () => setState(() {
                  showMapSettings = !showMapSettings;
                }),
              ),
            ),
            Positioned(
              top: 150,
              right: 15,
              child: FloatingActionButton.small(
                heroTag: null,
                foregroundColor: _locationUtils.enabled
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).disabledColor,
                child: const Icon(AppIcons.location),
                onPressed: () async {
                  if (_locationUtils.enabled) {
                    _locationUtils.stopLocationStream();
                    if (_circles != null) {
                      await _mapController.removeCircles(_circles!);
                    }
                    _circles = null;
                  } else {
                    _locationUtils.startLocationStream();
                  }
                  setState(() {});
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
