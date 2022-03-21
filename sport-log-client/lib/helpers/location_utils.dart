import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:sport_log/app.dart';

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

    await _location.changeSettings(accuracy: LocationAccuracy.high);
    // needs permission "always allow"
    while (true) {
      try {
        await _location.enableBackgroundMode(enable: true);
        break;
      } on PlatformException catch (_) {
        final ignore = await showDialog<bool>(
          context: AppState.globalContext,
          builder: (context) => AlertDialog(
            content: const Text(
              "In order to track the location while the screen is off the permission needs to be set to 'always allow'",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ignore'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Change Permission'),
              )
            ],
          ),
        );
        if (ignore == null || ignore) {
          break;
        }
      }
    }
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
