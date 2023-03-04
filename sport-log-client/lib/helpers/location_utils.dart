import 'dart:async';

import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class LocationUtils {
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _lastLatLng;

  Future<bool> startLocationStream(
    void Function(LocationData) onLocationUpdate,
  ) async {
    if (_locationSubscription != null) {
      return false;
    }

    // make sure "Allow When In Use" or "Request Every Time" is granted first
    // Request Every Time treated as Allow When In Use
    while (![
      PermissionStatus.authorizedWhenInUse,
      PermissionStatus.authorizedAlways
    ].contains(await requestPermission())) {
      final ignore = await showSystemSettingsDialog(
        text:
            "In order to track your location, the permission for location must be set to 'Allow When In Use'.",
      );
      if (ignore) {
        return false;
      }
    }

    // now that "Allow While In Use" is granted we can request "Allow Always"
    if (!await permission_handler.Permission.locationAlways.isGranted) {
      final ignore = await showSystemSettingsDialog(
        text:
            "In order to track your location in the background, the permission for location must be set to 'Allow Always'.",
      );
      if (ignore) {
        return false;
      }
    }
    while (!await permission_handler.Permission.locationAlways
        .request()
        .isGranted) {
      final ignore = await showSystemSettingsDialog(
        text:
            "In order to track your location in the background, the permission for location must be set to 'Allow Always'.",
      );
      if (ignore) {
        return false;
      }
    }

    // wait for first location before starting stream
    await getLocation(settings: LocationSettings(useGooglePlayServices: false));
    await setLocationSettings(useGooglePlayServices: false);
    _locationSubscription =
        onLocationChanged(inBackground: true).listen((locationData) async {
      await updateBackgroundNotification(
        title: "Sport Log Tracking",
        subtitle:
            "(${locationData.latitude?.toStringAsFixed(5)}, ${locationData.longitude?.toStringAsFixed(5)}) ~ ${locationData.accuracy?.round()} m [${locationData.satellites} satellites]",
        description: "test",
        onTapBringToFront: true,
      );
      _lastLatLng = locationData.latLng;
      onLocationUpdate(locationData);
    });
    return true;
  }

  Future<void> stopLocationStream() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  LatLng? get lastLatLng => _lastLatLng;

  bool get enabled => _locationSubscription != null;
}
