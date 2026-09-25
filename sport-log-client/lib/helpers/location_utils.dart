import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/request_permission.dart';
import 'package:sport_log/settings.dart';

class LocationUtils extends ChangeNotifier {
  LocationUtils();

  StreamSubscription<Position>? _locationSubscription;
  GpsPosition? _lastLocation;

  bool _disposed = false;

  static final _settings = AndroidSettings(
    forceLocationManager: true,
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: "Tracking",
      notificationText: "GPS tracking is active",
      color: Colors.red,
      notificationIcon: AndroidResource(name: "notification_icon"),
      setOngoing: true,
      enableWakeLock: true,
    ),
  );

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

  static Future<bool> requestPermissions() async {
    if (!await PermissionRequest.request(Permission.locationWhenInUse)) {
      return false;
    }
    // request permission but continue even if not granted
    await PermissionRequest.request(Permission.notification);
    // can request precise location - if not granted the use has to do it in settings in next step
    await Geolocator.requestPermission();
    if (!await Request.request(
      title: "Precise Location Required",
      text: "Please allow precise location.",
      check: () async =>
          (await Geolocator.getLocationAccuracy()) ==
          LocationAccuracyStatus.precise,
      change: Geolocator.openAppSettings,
    )) {
      return false;
    }
    if (!await Request.request(
      title: "GPS Required",
      text: "Please enable GPS.",
      check: Geolocator.isLocationServiceEnabled,
      change: Geolocator.openLocationSettings,
    )) {
      return false;
    }
    return true;
  }

  Future<bool> startLocationStream({
    required void Function(GpsPosition) onLocationUpdate,
  }) async {
    if (_locationSubscription != null) {
      return false;
    }

    if (!await requestPermissions()) {
      return false;
    }

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: _settings).listen(
          (position) => _onLocationUpdate(
            GpsPosition.fromGeolocatorPosition(position),
            onLocationUpdate,
          ),
        );
    notifyListeners();
    return true;
  }

  Future<void> _onLocationUpdate(
    GpsPosition position,
    void Function(GpsPosition) onLocationUpdate,
  ) async {
    // dispose cannot await stopLocationStream, so updates can still arrive after it
    if (_disposed) {
      return;
    }
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
  bool get hasLocation => _lastLocation?.latLng != null;
  bool get hasAccurateLocation =>
      hasLocation && (_lastLocation?.isGps ?? false);

  bool get enabled => _locationSubscription != null;
}
