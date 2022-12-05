import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/lat_lng_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMapController? _mapController;
  final _searchBar = FocusNode();
  final _placesSearch =
      PlacesSearch(apiKey: Config.instance.accessToken, limit: 10);

  bool _showOverlays = true;
  String? _search;
  List<MapBoxPlace> _searchResults = [];

  Future<void> _openDrawer(BuildContext context) async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
    if (mounted) {
      Scaffold.of(context).openDrawer();
    }
  }

  Future<void> _searchPlaces(String name) async {
    setState(() => _search = name);
    List<MapBoxPlace>? places;
    try {
      places = await _placesSearch.getPlaces(_search!);
    } on SocketException {
      showNoInternetToast(context);
    }
    if (mounted) {
      setState(() => _searchResults = places ?? []);
    }
  }

  void _toggleSearch() {
    setState(() {
      _search = _search == null ? "" : null;
      if (_search == null) {
        _searchResults = [];
      }
    });
    if (_search != null) {
      _searchBar.requestFocus();
    }
  }

  Future<void> _goToSearchItem(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final item = _searchResults[index];
    setState(() => _searchResults = []);

    final coords = item.center!;
    await _mapController?.animateCenter(LatLng(coords[1], coords[0]));

    final bbox = item.bbox;
    if (bbox != null) {
      await _mapController?.animateBounds(
        [LatLng(bbox[1], bbox[0]), LatLng(bbox[3], bbox[2])].latLngBounds!,
        padded: false,
      );
    } else {
      await _mapController?.animateZoom(16);
    }
  }

  static const _searchBackgroundColor = Color.fromARGB(150, 255, 255, 255);

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
                    onPressed: () => _openDrawer(context),
                  ),
                ),
                title: _search == null
                    ? null
                    : TextFormField(
                        focusNode: _searchBar,
                        onChanged: _searchPlaces,
                        onTap: () => _searchPlaces(_search ?? ""),
                        decoration: Theme.of(context).textFormFieldDecoration,
                        style: Theme.of(context)
                            .textTheme
                            .headline6!
                            .copyWith(color: Colors.black),
                      ),
                actions: [
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: Icon(
                      _search != null ? AppIcons.close : AppIcons.search,
                    ),
                  ),
                ],
                foregroundColor: Theme.of(context).colorScheme.background,
                backgroundColor: _searchBackgroundColor,
                elevation: 0,
              )
            : null,
        drawer: const MainDrawer(selectedRoute: Routes.map),
        body: Stack(
          alignment: Alignment.center,
          children: [
            MapboxMapWrapper(
              showScale: true,
              showFullscreenButton: false,
              showMapStylesButton: true,
              showSetNorthButton: true,
              showCurrentLocationButton: true,
              showSelectRouteButton: true,
              showOverlays: _showOverlays,
              buttonTopOffset: 120,
              onMapCreated: (controller) =>
                  setState(() => _mapController = controller),
              onMapClick: (_, __) =>
                  setState(() => _showOverlays = !_showOverlays),
            ),
            if (_showOverlays && _searchResults.isNotEmpty)
              Positioned(
                top: 56, // height of AppBar
                right: 0,
                left: 0,
                child: MapSearchResults(
                  searchResults: _searchResults,
                  backgroundColor: _searchBackgroundColor,
                  onItemTap: _goToSearchItem,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MapSearchResults extends StatelessWidget {
  const MapSearchResults({
    required this.searchResults,
    required this.backgroundColor,
    required this.onItemTap,
    super.key,
  });

  final List<MapBoxPlace> searchResults;
  final Color backgroundColor;
  final void Function(int) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Defaults.edgeInsets.normal,
      color: backgroundColor,
      constraints: const BoxConstraints(maxHeight: 200),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => onItemTap(index),
              child: Text(
                searchResults[index].toString(),
                style: Theme.of(context)
                    .textTheme
                    .subtitle1!
                    .copyWith(color: Colors.black),
              ),
            ),
            itemCount: searchResults.length,
            separatorBuilder: (context, index) => const Divider(),
            shrinkWrap: true,
          ),
        ),
      ),
    );
  }
}
