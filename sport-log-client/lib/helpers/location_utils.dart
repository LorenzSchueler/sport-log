import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/request_permission.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class LocationUtils extends ChangeNotifier {
  StreamSubscription<LocationData>? _locationSubscription;
  GpsPosition? _lastLocation;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    final lastGpsPosition = lastLatLng;
    if (lastGpsPosition != null) {
      Settings.instance.setLastGpsLatLng(lastGpsPosition);
    }
    stopLocationStream();
    super.dispose();
  }

  Future<bool> startLocationStream(
    void Function(GpsPosition) onLocationUpdate,
  ) async {
    if (_locationSubscription != null) {
      return false;
    }

    if (!await PermissionRequest.request(Permission.locationWhenInUse)) {
      return false;
    }
    if (!await Permission.locationAlways.isGranted) {
      final context = App.globalContext;
      if (context.mounted) {
        await showMessageDialog(
          context: context,
          text: "Location must be always allowed.",
        );
      }
    }
    // opens settings only once
    if (!await PermissionRequest.request(Permission.locationAlways)) {
      return false;
    }

    await setLocationSettings(useGooglePlayServices: false);
    _locationSubscription =
        onLocationChanged(inBackground: true).listen((locationData) {
      _onLocationUpdate(
        GpsPosition.fromLocationData(locationData),
        onLocationUpdate,
      );
    });
    notifyListeners();
    return true;
  }

  Future<void> _onLocationUpdate(
    GpsPosition position,
    void Function(GpsPosition) onLocationUpdate,
  ) async {
    await updateBackgroundNotification(
      title: "Sport Log Tracking",
      subtitle:
          "(${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}) ~ ${position.accuracy.round()} m [${position.satellites} satellites]",
      description: "test",
      onTapBringToFront: true,
    );
    _lastLocation = position;
    onLocationUpdate(position);
    notifyListeners();
  }

  Future<void> stopLocationStream() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastLocation = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  GpsPosition? get lastLocation => _lastLocation;
  LatLng? get lastLatLng => _lastLocation?.latLng;
  bool get hasGps =>
      (_lastLocation?.isGps ?? false) && _lastLocation?.latLng != null;

  bool get enabled => _locationSubscription != null;
}
