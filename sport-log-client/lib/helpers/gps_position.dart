import 'package:geolocator/geolocator.dart';
import 'package:sport_log/helpers/lat_lng.dart';

class GpsPosition {
  const GpsPosition({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.accuracy,
    required this.satellites,
  });

  GpsPosition.fromGeolocatorPosition(Position locationData)
      : latitude = locationData.latitude,
        longitude = locationData.longitude,
        elevation = locationData.altitude,
        accuracy = locationData.accuracy,
        satellites = (locationData is AndroidPosition)
            ? locationData.satellitesUsedInFix.toInt()
            : 0;

  final double latitude;
  final double longitude;
  final double elevation;
  final double accuracy;
  final int satellites;

  LatLng get latLng => LatLng(lat: latitude, lng: longitude);

  bool get isGps => satellites >= 3 && accuracy <= 20;

  @override
  String toString() {
    return "$latLng, ele: ${elevation.round()}, accuracy: ${accuracy.round()}, sat: $satellites";
  }
}
