import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

extension LocationDataExtension on LocationData {
  LatLng get latLng => LatLng(latitude!, longitude!);
}
