import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
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

  List<Circle> _circles = [];

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
    if (_locationUtils.lastLatLng != null) {
      Settings.lastGpsLatLng = _locationUtils.lastLatLng!;
    }
    _mapController.removeListener(_mapControllerListener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _mapControllerListener() async {
    final latitude = _mapController.cameraPosition!.target.latitude;

    final metersPerPixel =
        await _mapController.getMetersPerPixelAtLatitude(latitude);
    setState(() => _metersPerPixel = metersPerPixel);
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    await _mapController.animateCamera(CameraUpdate.newLatLng(location.latLng));
    _circles = await _mapController.updateCurrentLocationMarker(
      _circles,
      location.latLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return NeverPop(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _showOverlays
            ? AppBar(
                foregroundColor: Theme.of(context).colorScheme.background,
                backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                elevation: 0,
              )
            : null,
        drawer: const MainDrawer(selectedRoute: Routes.map),
        body: Stack(
          children: [
            MapboxMap(
              accessToken: Config.instance.accessToken,
              styleString: mapStyle,
              initialCameraPosition: Settings.lastMapPosition,
              trackCameraPosition: true,
              onMapCreated: (MapboxMapController controller) => _mapController =
                  controller..addListener(_mapControllerListener),
              onMapClick: (_, __) => setState(() {
                _showOverlays = !_showOverlays;
              }),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: MapScale(metersPerPixel: _metersPerPixel),
            ),
            if (_showOverlays) ...[
              Positioned(
                top: 100,
                right: 15,
                child: FloatingActionButton.small(
                  heroTag: null,
                  child: const Icon(AppIcons.map),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(AppIcons.map),
                          onPressed: () {
                            setState(() {
                              mapStyle = Defaults.mapbox.style.outdoor;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.car),
                          onPressed: () {
                            setState(() {
                              mapStyle = Defaults.mapbox.style.street;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.satellite),
                          onPressed: () {
                            setState(() {
                              mapStyle = Defaults.mapbox.style.satellite;
                            });
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                  ),
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
                    if (mounted) {
                      setState(() {});
                    }
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
