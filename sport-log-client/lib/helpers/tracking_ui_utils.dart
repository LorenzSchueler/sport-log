import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';

class TrackingUiUtils {
  MapController? _mapController;
  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();

  bool _centerLocation = true;
  void setCenterLocation(bool centerLocation, LatLng? latLng) {
    _centerLocation = centerLocation;
    centerCurrentLocation(latLng);
  }

  Future<void> onMapCreated(
    MapController mapController,
    Route? route,
  ) async {
    _mapController = mapController;
    final track = route?.track;
    if (track != null) {
      await _mapController?.addRouteLine(track);
    }
  }

  Future<void> updateTrack(List<Position>? track) async {
    await _mapController?.updateTrackLine(_line, track);
  }

  Future<void> updateLocation(GpsPosition location) async {
    await centerCurrentLocation(location.latLng);
    await _mapController?.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
      location.isGps,
    );
  }

  Future<void> centerCurrentLocation(LatLng? latLng) async {
    if (_centerLocation && latLng != null) {
      await _mapController?.animateCenter(latLng);
    }
  }
}
