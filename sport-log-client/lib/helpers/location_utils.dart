import 'dart:async';

import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class LocationUtils {
  static final Location _location = Location();

  void Function(LocationData) onLocationUpdate;
  StreamSubscription? _locationSubscription;

  LocationUtils(this.onLocationUpdate);

  static Future<bool> enableLocation() async {
    while (!await _location.requestService()) {
      final ignore = await showSystemSettingsDialog(
        text: "In order to track your location GPS must be enabled.",
      );
      if (ignore == null || ignore) {
        return false;
      }
    }
    return true;
  }

  Future<bool> startLocationStream() async {
    if (_locationSubscription == null) {
      if (!await enableLocation()) {
        return false;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return false;
        }
      }

      await _location.changeSettings(accuracy: LocationAccuracy.high);
      // needs permission "always allow"
      while (true) {
        try {
          await _location.enableBackgroundMode(enable: true);
          break;
        } on PlatformException catch (_) {
          final ignore = await showSystemSettingsDialog(
            text:
                "In order to track your location while the screen is off the permission needs to be set to 'always allow'",
          );
          if (ignore == null || ignore) {
            return false;
          }
        }
      }
      _locationSubscription =
          _location.onLocationChanged.listen(onLocationUpdate);
    }
    return true;
  }

  void stopLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _location.enableBackgroundMode(enable: false);
  }

  bool get enabled => _locationSubscription != null;
}
