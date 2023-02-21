import 'dart:async';

import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class LocationUtils {
  LocationUtils(this.onLocationUpdate);

  static final Location _location = Location();

  void Function(LocationData) onLocationUpdate;
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _lastLatLng;

  static Future<bool> enableLocation() async {
    while (!await _location.requestService()) {
      final ignore = await showSystemSettingsDialog(
        text: "In order to track your location GPS must be enabled.",
      );
      if (ignore) {
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
              "In order to track your location the permission needs to be 'allowed'.",
        );
        if (ignore) {
          return false;
        }
      }

      if (!await Permission.locationAlways.isGranted) {
        final context = App.globalContext;
        if (context.mounted) {
          await showMessageDialog(
            context: context,
            text:
                "In order to track your location while the screen is off the permission needs to be set to 'always allow'.",
          );
        }
      }
      while (!await Permission.locationAlways.request().isGranted) {
        final ignore = await showSystemSettingsDialog(
          text:
              "In order to track your location while the screen is off the permission needs to be set to 'always allow'.",
        );
        if (ignore) {
          return false;
        }
      }
      await _location.enableBackgroundMode();
      await _location.changeSettings();
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
