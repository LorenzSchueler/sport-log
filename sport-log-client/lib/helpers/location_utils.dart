import 'dart:async';

import 'package:location/location.dart';

class LocationUtils {
  void Function(LocationData) onLocationUpdate;

  final Location _location = Location();
  StreamSubscription? _locationSubscription;

  LocationUtils(this.onLocationUpdate);

  Future<void> startLocationStream() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _location.changeSettings(accuracy: LocationAccuracy.high);
    // needs permission "always allow"
    _location.enableBackgroundMode(enable: true);
    // fails if background enabled but persission not "always allow"
    _locationSubscription =
        _location.onLocationChanged.listen(onLocationUpdate);
  }

  void stopLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _location.enableBackgroundMode(enable: false);
  }

  bool get enabled => _locationSubscription != null;
}
