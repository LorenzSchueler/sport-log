import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/lat_lng_extension.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
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
  final _searchBar = FocusNode();
  final placesSearch =
      PlacesSearch(apiKey: Config.instance.accessToken, limit: 10);

  bool _showOverlays = true;
  String? _search;
  List<MapBoxPlace> _searchResults = [];
  bool _searchResultsVisible = false;

  List<Circle> _circles = [];
  double _metersPerPixel = 1;
  String _mapStyle = MapboxStyles.OUTDOORS;
  bool _hillshade = false;

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
    super.dispose();
  }

  Future<void> _mapControllerListener() async {
    final latitude = _mapController.cameraPosition!.target.latitude;

    final metersPerPixel =
        await _mapController.getMetersPerPixelAtLatitude(latitude);
    setState(() => _metersPerPixel = metersPerPixel);
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    await _mapController.animateCenter(location.latLng);
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
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(AppIcons.drawer),
                    onPressed: () async {
                      await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                      await SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitUp],
                      );
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                title: _search == null
                    ? null
                    : TextFormField(
                        focusNode: _searchBar,
                        onChanged: (name) async {
                          _search = name;
                          final places = await placesSearch.getPlaces(_search!);
                          setState(() {
                            _searchResults = places ?? [];
                            _searchResultsVisible = true;
                          });
                        },
                        decoration: Theme.of(context).textFormFieldDecoration,
                      ),
                actions: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _search = _search == null ? "" : null;
                        if (_search == null) {
                          _searchResults = [];
                          _searchResultsVisible = false;
                        }
                      });
                      if (_search != null) {
                        _searchBar.requestFocus();
                      }
                    },
                    icon: Icon(
                      _search != null ? AppIcons.close : AppIcons.search,
                    ),
                  ),
                ],
              )
            : null,
        drawer: const MainDrawer(selectedRoute: Routes.map),
        body: Stack(
          alignment: Alignment.center,
          children: [
            MapboxMap(
              accessToken: Config.instance.accessToken,
              styleString: _mapStyle,
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
            if (_showOverlays)
              Positioned(
                top: 120,
                right: 15,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: null,
                      child: const Icon(AppIcons.layers),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => MapStylesBottomSheet(
                          hillshade: _hillshade,
                          mapController: _mapController,
                          onStyleChange: (style) =>
                              setState(() => _mapStyle = style),
                          onHillshadeChange: (hillshade) =>
                              setState(() => _hillshade = hillshade),
                        ),
                      ),
                    ),
                    Defaults.sizedBox.vertical.normal,
                    FloatingActionButton.small(
                      heroTag: null,
                      child: Icon(
                        _locationUtils.enabled
                            ? AppIcons.myLocation
                            : AppIcons.myLocationDisabled,
                      ),
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
                    Defaults.sizedBox.vertical.normal,
                    FloatingActionButton.small(
                      heroTag: null,
                      child: const Icon(AppIcons.compass),
                      onPressed: () => _mapController.setNorth(),
                    ),
                  ],
                ),
              ),
            if (_showOverlays && _searchResultsVisible)
              Positioned(
                top: 56,
                right: 0,
                left: 0,
                child: Container(
                  padding: Defaults.edgeInsets.normal,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Scrollbar(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          setState(() => _searchResultsVisible = false);
                          FocusScope.of(context)
                              .requestFocus(FocusNode()); // unfocus
                          final coords = _searchResults[index].center!;
                          final latLng = LatLng(coords[1], coords[0]);
                          _mapController.animateCenter(latLng);

                          final bbox = _searchResults[index].bbox;
                          if (bbox != null) {
                            final bounds = [
                              LatLng(bbox[1], bbox[0]),
                              LatLng(bbox[3], bbox[2])
                            ].latLngBounds!;
                            _mapController.animateBounds(bounds, padded: false);
                          } else {
                            _mapController.animateZoom(16);
                          }
                        },
                        child: Text(
                          _searchResults[index].toString(),
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      ),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(),
                      shrinkWrap: true,
                    ),
                  ),
                ),
              ),
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

class MapStylesBottomSheet extends StatelessWidget {
  final bool hillshade;
  final MapboxMapController mapController;
  final void Function(String style) onStyleChange;
  final void Function(bool hillshade) onHillshadeChange;

  MapStylesBottomSheet({
    required this.hillshade,
    required this.mapController,
    required this.onStyleChange,
    required this.onHillshadeChange,
    Key? key,
  }) : super(key: key);

  final style = ButtonStyle(
    shape: MaterialStateProperty.all(const CircleBorder()),
    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Defaults.edgeInsets.normal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Icon(AppIcons.mountains),
                onPressed: () {
                  onStyleChange(MapboxStyles.OUTDOORS);
                  onHillshadeChange(false);
                  Navigator.of(context).pop();
                },
                style: style,
              ),
              ElevatedButton(
                child: const Icon(AppIcons.car),
                onPressed: () {
                  onStyleChange(MapboxStyles.MAPBOX_STREETS);
                  onHillshadeChange(false);
                  Navigator.of(context).pop();
                },
                style: style,
              ),
              ElevatedButton(
                child: const Icon(AppIcons.satellite),
                onPressed: () {
                  onStyleChange(MapboxStyles.SATELLITE);
                  onHillshadeChange(false);
                  Navigator.of(context).pop();
                },
                style: style,
              ),
            ],
          ),
          Defaults.sizedBox.vertical.normal,
          ElevatedButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hillshade ? AppIcons.close : AppIcons.add),
                Defaults.sizedBox.horizontal.normal,
                const Text("Hillshade"),
              ],
            ),
            onPressed: () {
              if (hillshade) {
                mapController.removeLayer("hillshadeX");
              } else {
                mapController
                  ..addSource(
                    'dem',
                    const RasterDemSourceProperties(
                      url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
                    ),
                  )
                  ..addHillshadeLayer(
                    "dem",
                    "hillshadeX",
                    HillshadeLayerProperties(
                      hillshadeShadowColor:
                          const Color.fromARGB(255, 60, 60, 60)
                              .toHexStringRGB(),
                      hillshadeHighlightColor:
                          const Color.fromARGB(255, 60, 60, 60)
                              .toHexStringRGB(),
                    ),
                  );
              }
              onHillshadeChange(!hillshade);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
