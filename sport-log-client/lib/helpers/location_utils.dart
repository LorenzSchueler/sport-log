import 'dart:async';

import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class LocationUtils {
  static final Location _location = Location();

  void Function(LocationData) onLocationUpdate;
  StreamSubscription? _locationSubscription;
  LatLng? _lastLatLng;

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

      while (!await Permission.locationWhenInUse.request().isGranted) {
        final ignore = await showSystemSettingsDialog(
          text:
              "In order to track your location the permission needs to be 'allowed'",
        );
        if (ignore == null || ignore) {
          return false;
        }
      }
      while (!await Permission.locationAlways.request().isGranted) {
        final ignore = await showSystemSettingsDialog(
          text:
              "In order to track your location while the screen is off the permission needs to be set to 'always allow'",
        );
        if (ignore == null || ignore) {
          return false;
        }
      }
      await _location.enableBackgroundMode(enable: true);
      await _location.changeSettings(accuracy: LocationAccuracy.high);
      _locationSubscription =
          _location.onLocationChanged.listen((locationData) {
        _lastLatLng = locationData.latLng;
        onLocationUpdate(locationData);
      });
    }
    return true;
  }

  void stopLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _location.enableBackgroundMode(enable: false);
  }

  LatLng? get lastLatLng => _lastLatLng;

  bool get enabled => _locationSubscription != null;
}
