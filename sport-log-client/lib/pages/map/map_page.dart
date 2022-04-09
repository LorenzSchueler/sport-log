import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/never_pop.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late LocationUtils _locationUtils;
  late MapboxMapController _mapController;
  bool _showOverlays = true;
  bool _showMapSettings = false;

  List<Circle> _circles = [];
  LatLng? _lastLatLng;

  double _metersPerPixel = 1;

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
    _mapController.removeListener(_mapControllerListener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _mapControllerListener() async {
    final latitude = _mapController.cameraPosition!.target.latitude;

    final metersPerPixel =
        await _mapController.getMetersPerPixelAtLatitude(latitude);
    setState(() => _metersPerPixel = metersPerPixel);
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    _lastLatLng = LatLng(location.latitude!, location.longitude!);

    await _mapController.animateCamera(
      CameraUpdate.newLatLng(_lastLatLng!),
    );
    _circles = await _mapController.updateCurrentLocationMarker(
      _circles,
      _lastLatLng!,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return NeverPop(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _showOverlays
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
              onMapCreated: (MapboxMapController controller) => _mapController =
                  controller..addListener(_mapControllerListener),
              onMapClick: (_, __) => setState(() {
                _showOverlays = !_showOverlays;
                _showMapSettings = false;
              }),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: MapScale(metersPerPixel: _metersPerPixel),
            ),
            if (_showMapSettings)
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
            if (_showOverlays) ...[
              Positioned(
                top: 100,
                right: 15,
                child: FloatingActionButton.small(
                  heroTag: null,
                  child: const Icon(AppIcons.map),
                  onPressed: () => setState(() {
                    _showMapSettings = !_showMapSettings;
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
                      if (_circles.isNotEmpty) {
                        await _mapController.removeCircles(_circles);
                      }
                      _circles = [];
                    } else {
                      await _locationUtils.startLocationStream();
                    }
                    setState(() {});
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MapScale extends StatelessWidget {
  final double metersPerPixel;

  const MapScale({required this.metersPerPixel, Key? key}) : super(key: key);

  double get _scaleWidth {
    const maxWidth = 200;
    final maxWidthMeters = maxWidth * metersPerPixel;
    final fac = maxWidthMeters / pow(10, (log(maxWidthMeters) / ln10).floor());
    if (fac >= 1 && fac < 2) {
      return maxWidth / fac;
    } else if (fac < 5) {
      return maxWidth / fac * 2;
    } else {
      // fac < 10
      return maxWidth / fac * 5;
    }
  }

  int get _scaleLength {
    return (_scaleWidth * metersPerPixel).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _scaleWidth,
      color: Theme.of(context).colorScheme.background,
      child: Text(
        _scaleLength >= 1000
            ? "${(_scaleLength / 1000).round()} km"
            : "$_scaleLength m",
        textAlign: TextAlign.center,
      ),
    );
  }
}
