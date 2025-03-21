import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/request_permission.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class LocationUtils extends ChangeNotifier {
  LocationUtils({required this.inBackground});

  final bool inBackground;

  StreamSubscription<Position>? _locationSubscription;
  GpsPosition? _lastLocation;

  bool _disposed = false;

  late final _settings = AndroidSettings(
    forceLocationManager: true,
    foregroundNotificationConfig:
        inBackground
            ? const ForegroundNotificationConfig(
              notificationTitle: "Tracking",
              notificationText: "GPS tracking is active",
              color: Colors.red,
              notificationIcon: AndroidResource(name: "notification_icon"),
              setOngoing: true,
              enableWakeLock: true,
            )
            : null,
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
    if (!await Permission.locationAlways.isGranted) {
      final context = App.globalContext;
      if (context.mounted) {
        await showMessageDialog(
          context: context,
          title: "Permission Required",
          text: "Location must be always allowed.",
        );
      }
    }
    // opens settings only once
    if (!await PermissionRequest.request(Permission.locationAlways)) {
      return false;
    }
    // request permission but continue even if not granted
    await PermissionRequest.request(Permission.notification);
    // can request precise location - if not granted the use has to do it in settings in next step
    await Geolocator.requestPermission();
    if (!await Request.request(
      title: "Precise Location Required",
      text: "Please allow precise location.",
      check:
          () async =>
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
    required bool inBackground,
  }) async {
    if (_locationSubscription != null) {
      return false;
    }

    if (!await requestPermissions()) {
      return false;
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: _settings,
    ).listen((Position position) {
      _onLocationUpdate(
        GpsPosition.fromGeolocatorPosition(position),
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
