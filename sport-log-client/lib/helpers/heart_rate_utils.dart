import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class HeartRateUtils {
  static final _polar = Polar();
  static final FlutterBlue _flutterBlue = FlutterBlue.instance;

  final String deviceId;
  final void Function(PolarHeartRateEvent) onHeartRateEvent;
  final void Function(PolarBatteryLevelEvent)? onBatteryEvent;
  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _batterySubscription;
  bool _active = false;

  HeartRateUtils({
    required this.deviceId,
    required this.onHeartRateEvent,
    this.onBatteryEvent,
  });

  static Future<Map<String, String>?> searchDevices() async {
    while (!await _flutterBlue.isOn) {
      final ignore = await showSystemSettingsDialog(
        text:
            "In order to discover heart rate monitors bluetooth must be enabled.",
      );
      if (ignore) {
        return null;
      }
      await AppSettings.openBluetoothSettings();
    }

    if (!await LocationUtils.enableLocation()) {
      return null;
    }

    final Map<String, String> map = {};
    await for (final d
        in _flutterBlue.scan(timeout: const Duration(seconds: 10))) {
      if (d.device.name.toLowerCase().contains("polar h")) {
        map.putIfAbsent(d.device.name, d.device.id.toString);
      }
    }

    return map.isEmpty ? null : map;
  }

  void startHeartRateStream() {
    if (_heartRateSubscription == null) {
      _heartRateSubscription = _polar.heartRateStream.listen((heartRateEvent) {
        _active = true;
        onHeartRateEvent(heartRateEvent);
      });
      if (onBatteryEvent != null) {
        _batterySubscription = _polar.batteryLevelStream.listen(onBatteryEvent);
      }
      _polar.connectToDevice(deviceId);
    }
  }

  void stopHeartRateStream() {
    _heartRateSubscription?.cancel();
    _batterySubscription?.cancel();
    _polar.disconnectFromDevice(deviceId);
  }

  bool get active => _active;

  bool get enabled => _heartRateSubscription != null;
}
