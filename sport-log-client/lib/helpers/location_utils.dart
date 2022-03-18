import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:sport_log/helpers/logger.dart';

class LocationUtils {
  void Function(Position) onLocationUpdate;
  StreamSubscription<Position>? _positionStream;

  LocationUtils(this.onLocationUpdate);

  Future<String?> startLocationStream() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return "GPS must be enabled in order to track your position.";
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Sport-Log must be allowd to access your position in order to track your position.";
      }
    }

    _positionStream = Geolocator.getPositionStream().listen(
      (Position? position) => position == null
          ? Logger("LocationUtils").i("position == null")
          : onLocationUpdate(position),
    );
    return null;
  }

  void stopLocationStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  bool get enabled => _positionStream != null;

  Future<Position?> get lastPosition => Geolocator.getLastKnownPosition();
}
