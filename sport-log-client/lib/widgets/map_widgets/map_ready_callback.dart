import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/map_controller.dart';

class MapReadyCallback {
  MapReadyCallback(this.onReady);

  final void Function(MapController) onReady;

  bool _done = false;
  bool _mapLoaded = false;
  MapController? _mapController;

  void onMapCreated(MapController mapController) {
    _mapController = mapController;
    _maybeReady();
  }

  void onMapLoaded(MapLoadedEventData _) {
    _mapLoaded = true;
    _maybeReady();
  }

  void _maybeReady() {
    if (_mapLoaded && _mapController != null && !_done) {
      _done = true;
      onReady(_mapController!);
    }
  }
}
