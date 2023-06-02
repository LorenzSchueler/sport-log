import 'package:location/location.dart';
import 'package:sport_log/helpers/lat_lng.dart';

extension LocationDataExtension on LocationData {
  LatLng get latLng => LatLng(lat: latitude!, lng: longitude!);

  bool get isGps =>
      (satellites ?? 0) >= 3 && (accuracy ?? double.infinity) <= 20;
}
