import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/search.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';

class TrackingUiUtils {
  TrackingUiUtils(Route? route, CardioSession? cardioSession)
      : _routeTrack = route?.track,
        _cardioSessionTrack = cardioSession?.track;

  MapController? _mapController;
  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _compareLocationMarker =
      NullablePointer.nullPointer();

  final List<Position>? _routeTrack;
  final List<Position>? _cardioSessionTrack;

  bool _centerLocation = true;
  void setCenterLocation(bool centerLocation, LatLng? latLng) {
    _centerLocation = centerLocation;
    centerCurrentLocation(latLng);
  }

  Future<void> onMapCreated(MapController mapController) async {
    _mapController = mapController;
    if (_routeTrack != null) {
      await _mapController?.addRouteLine(_routeTrack!);
    }
    if (_cardioSessionTrack != null) {
      await _mapController?.addRouteLine(_cardioSessionTrack!);
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

  Future<void> updateSessionProgressMarker(Duration currentDuration) async {
    if (_cardioSessionTrack != null) {
      final comparePositionIdx = binarySearchLargestLE(
        _cardioSessionTrack!,
        (pos) => pos.time,
        currentDuration,
      );
      if (comparePositionIdx != null) {
        final comparePosition = _cardioSessionTrack![comparePositionIdx];
        await _mapController?.updateRouteMarker(
          _compareLocationMarker,
          comparePosition.latLng,
        );
      }
    }
  }

  Future<void> centerCurrentLocation(LatLng? latLng) async {
    if (_centerLocation && latLng != null) {
      await _mapController?.animateCenter(latLng);
    }
  }
}
