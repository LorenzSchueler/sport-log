import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/map_search_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class MapPage extends StatelessWidget {
  MapPage({super.key});

  static const _searchBackgroundColor = Color.fromARGB(150, 255, 255, 255);

  final _searchBar = FocusNode();

  Future<void> _onDrawerChanged(bool open) async {
    if (open) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
    } else {
      await _setOrientation();
    }
  }

  Future<void> _setOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _setOrientation();

    return NeverPop(
      child: ProviderConsumer(
        create: (_) => BoolToggle.on(),
        builder: (context, showOverlays, _) => ProviderConsumer(
          create: (_) => MapSearchUtils(),
          builder: (context, searchUtils, _) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: showOverlays.isOn
                ? AppBar(
                    title: searchUtils.search == null
                        ? null
                        : TextFormField(
                            focusNode: _searchBar,
                            onChanged: searchUtils.searchPlaces,
                            onTap: () => searchUtils
                                .searchPlaces(searchUtils.search ?? ""),
                            style: const TextStyle(color: Colors.black),
                          ),
                    actions: [
                      IconButton(
                        onPressed: () => searchUtils.toggleSearch(_searchBar),
                        icon: Icon(
                          searchUtils.search != null
                              ? AppIcons.close
                              : AppIcons.search,
                        ),
                      ),
                    ],
                    foregroundColor: Theme.of(context).colorScheme.background,
                    backgroundColor: _searchBackgroundColor,
                    elevation: 0,
                  )
                : null,
            drawer: const MainDrawer(selectedRoute: Routes.map),
            onDrawerChanged: _onDrawerChanged,
            body: Stack(
              alignment: Alignment.center,
              children: [
                MapboxMapWrapper(
                  showFullscreenButton: false,
                  showMapStylesButton: true,
                  showSelectRouteButton: true,
                  showSetNorthButton: true,
                  showCurrentLocationButton: true,
                  showCenterLocationButton: true,
                  showOverlays: showOverlays.isOn,
                  buttonTopOffset: 100,
                  onMapCreated: searchUtils.setMapController,
                  onTap: (_) => showOverlays.toggle(),
                ),
                if (showOverlays.isOn && searchUtils.searchResults.isNotEmpty)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: MapSearchResults(
                        searchResults: searchUtils.searchResults,
                        backgroundColor: _searchBackgroundColor,
                        onItemTap: searchUtils.goToSearchItem,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                searchResults[index].placeName ?? "unknown",
                style: const TextStyle(color: Colors.black),
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
