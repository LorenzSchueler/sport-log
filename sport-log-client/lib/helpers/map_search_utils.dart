import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MapSearchUtils extends ChangeNotifier {
  final _searchApi = GeoCodingApi(
    apiKey: Config.instance.accessToken,
    limit: 10,
    types: PlaceType.values,
  );
  MapController? _mapController;
  void setMapController(MapController mapController) =>
      _mapController = mapController;

  List<MapBoxPlace>? _searchResults;
  List<MapBoxPlace>? get searchResults => _searchResults;
  bool get isSearchActive => _searchResults != null;

  void toggleSearch(FocusNode searchBar) {
    _searchResults = _searchResults == null ? [] : null;
    notifyListeners();
    if (_searchResults != null) {
      searchBar.requestFocus();
    }
  }

  Future<void> searchPlaces(String name) async {
    notifyListeners();
    try {
      final pos = await _mapController?.center;
      final places = await _searchApi.getPlaces(
        name,
        proximity:
            pos != null
                ? Proximity.LatLong(lat: pos.lat, long: pos.lng)
                : Proximity.LocationNone(),
      );
      _searchResults = places.success ?? [];
      notifyListeners();
    } on SocketException {
      final context = App.globalContext;
      if (context.mounted) {
        showNoInternetToast(context);
      }
    }
  }

  Future<void> goToSearchItem(MapBoxPlace place) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchResults = null;
    notifyListeners();

    final bbox = place.bbox;
    final center = place.center;
    if (bbox != null) {
      final bounds =
          [
            LatLng(lat: bbox.min.lat, lng: bbox.min.long),
            LatLng(lat: bbox.max.lat, lng: bbox.max.long),
          ].latLngBounds!;
      await _mapController?.setBoundsX(bounds, padded: false);
    } else if (center != null) {
      await _mapController?.animateCenter(
        LatLng(lat: center.lat, lng: center.long),
      );
      await _mapController?.setZoom(16);
    }
  }
}
