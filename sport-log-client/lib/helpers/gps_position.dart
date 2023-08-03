import 'package:location/location.dart';
import 'package:sport_log/helpers/lat_lng.dart';

class GpsPosition {
  const GpsPosition({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.accuracy,
    required this.satellites,
  });

  GpsPosition.fromLocationData(LocationData locationData)
      : latitude = locationData.latitude!,
        longitude = locationData.longitude!,
        elevation = locationData.altitude ?? 0,
        accuracy = locationData.accuracy ?? 0,
        satellites = locationData.satellites ?? 0;

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
