import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class LocationUtils extends ChangeNotifier {
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _lastLatLng;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    final lastGpsPosition = lastLatLng;
    if (lastGpsPosition != null) {
      Settings.instance.lastGpsLatLng = lastGpsPosition;
    }
    stopLocationStream();
    super.dispose();
  }

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
      final systemSettings = await showSystemSettingsDialog(
        text:
            "In order to track your location, the permission for location must be set to 'Allow When In Use'.",
      );
      if (systemSettings.isIgnore) {
        return false;
      }
    }

    // now that "Allow While In Use" is granted we can request "Allow Always"
    if (!await permission_handler.Permission.locationAlways.isGranted) {
      final systemSettings = await showSystemSettingsDialog(
        text:
            "In order to track your location in the background, the permission for location must be set to 'Allow Always'.",
      );
      if (systemSettings.isIgnore) {
        return false;
      }
    }
    while (!await permission_handler.Permission.locationAlways
        .request()
        .isGranted) {
      final systemSettings = await showSystemSettingsDialog(
        text:
            "In order to track your location in the background, the permission for location must be set to 'Allow Always'.",
      );
      if (systemSettings.isIgnore) {
        return false;
      }
    }

    await setLocationSettings(useGooglePlayServices: false);
    _locationSubscription = onLocationChanged(inBackground: true).listen(
      (locationData) => _onLocationUpdate(locationData, onLocationUpdate),
    );
    notifyListeners();
    return true;
  }

  Future<void> _onLocationUpdate(
    LocationData locationData,
    void Function(LocationData) onLocationUpdate,
  ) async {
    await updateBackgroundNotification(
      title: "Sport Log Tracking",
      subtitle:
          "(${locationData.latitude?.toStringAsFixed(5)}, ${locationData.longitude?.toStringAsFixed(5)}) ~ ${locationData.accuracy?.round()} m [${locationData.satellites} satellites]",
      description: "test",
      onTapBringToFront: true,
    );
    _lastLatLng = locationData.latLng;
    onLocationUpdate(locationData);
    notifyListeners();
  }

  Future<void> stopLocationStream() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastLatLng = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  LatLng? get lastLatLng => _lastLatLng;

  bool get enabled => _locationSubscription != null;
}
