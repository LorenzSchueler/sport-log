import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/mapbox_search_box_api.dart';
import 'package:sport_log/helpers/mapbox_search_models.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MapboxSearchResult {
  MapboxSearchResult({
    required this.name,
    required this.address,
    required this.latLng,
    required this.bounds,
  });

  factory MapboxSearchResult.fromFeature(Feature r) {
    final props = r.properties;
    final coords = r.geometry.coordinates;
    final bbox = props.bbox;
    return MapboxSearchResult(
      name: props.name,
      address: props.fullAddress,
      latLng: LatLng(lat: coords.latitude, lng: coords.longitude),
      bounds: bbox != null
          ? [
              LatLng(lat: bbox.minLatitude, lng: bbox.minLongitude),
              LatLng(lat: bbox.maxLatitude, lng: bbox.maxLongitude),
            ].latLngBounds
          : null,
    );
  }

  String name;
  String? address;
  LatLng latLng;
  LatLngBounds? bounds;
}

class MapSearchUtils extends ChangeNotifier {
  final _searchApi = MapboxSearchBoxApi(
    accessToken: Config.instance.accessToken,
  );
  MapController? _mapController;
  void setMapController(MapController mapController) =>
      _mapController = mapController;

  List<MapboxSearchResult>? _searchResults;
  List<MapboxSearchResult>? get searchResults => _searchResults;
  bool get isSearchActive => _searchResults != null;

  void toggleSearch(FocusNode searchBar) {
    _searchResults = _searchResults == null ? [] : null;
    notifyListeners();
    if (_searchResults != null) {
      searchBar.requestFocus();
    }
  }

  Future<void> searchPlaces(String name) async {
    final center = await _mapController?.center;
    final response = await _searchApi.search(
      searchText: name,
      proximity: center,
    );
    response
      ..onOk((result) {
        _searchResults = result.map(MapboxSearchResult.fromFeature).toList();
        notifyListeners();
      })
      ..onErr((error) {
        final context = App.globalContext;
        if (context.mounted) {
          showNoInternetToast(context);
        }
      });
  }

  Future<void> goToSearchItem(MapboxSearchResult result) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchResults = null;
    notifyListeners();

    final bounds = result.bounds;
    if (bounds != null) {
      await _mapController?.setBoundsX(bounds, padded: false);
    } else {
      await _mapController?.animateCenter(result.latLng);
    }
    await _mapController?.setZoom(16);
  }
}
