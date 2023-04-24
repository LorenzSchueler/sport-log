import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MapSearchUtils extends ChangeNotifier {
  final _placesSearch =
      PlacesSearch(apiKey: Config.instance.accessToken, limit: 10);
  MapController? _mapController;
  void setMapController(MapController mapController) =>
      _mapController = mapController;

  String? _search;
  String? get search => _search;
  List<MapBoxPlace> _searchResults = [];
  List<MapBoxPlace> get searchResults => _searchResults;

  void toggleSearch(FocusNode searchBar) {
    _search = _search == null ? "" : null;
    if (_search == null) {
      _searchResults = [];
    }
    notifyListeners();
    if (_search != null) {
      searchBar.requestFocus();
    }
  }

  Future<void> searchPlaces(String name) async {
    _search = name;
    notifyListeners();
    List<MapBoxPlace>? places;
    try {
      places = await _placesSearch.getPlaces(_search!);
    } on SocketException {
      showNoInternetToast(App.globalContext);
    }
    _searchResults = places ?? [];
    notifyListeners();
  }

  Future<void> goToSearchItem(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final item = _searchResults[index];
    _searchResults = [];
    notifyListeners();

    final bbox = item.bbox;
    final center = item.center;
    if (bbox != null) {
      final bounds = [
        LatLng(lat: bbox[1], lng: bbox[0]),
        LatLng(lat: bbox[3], lng: bbox[2])
      ].latLngBounds!;
      await _mapController?.setBoundsX(bounds, padded: false);
    } else if (center != null) {
      await _mapController
          ?.animateCenter(LatLng(lat: center[1], lng: center[0]));
      await _mapController?.setZoom(16);
    }
  }
}
