import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/helpers/location_utils.dart';

class HeartRateUtils {
  static final _polar = Polar();
  static final FlutterBlue _flutterBlue = FlutterBlue.instance;

  final String _deviceId;
  final void Function(PolarHeartRateEvent) _onHeartRateEvent;
  StreamSubscription? _heartRateSubscription;

  HeartRateUtils(this._deviceId, this._onHeartRateEvent);

  static Future<Map<String, String>?> searchDevices() async {
    while (!await _flutterBlue.isOn) {
      final ignore = await showDialog<bool>(
        context: AppState.globalContext,
        builder: (context) => AlertDialog(
          content: const Text(
            "In order to discover heart rate monitors bluetooth must be enabled.",
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
        return null;
      }
      await AppSettings.openBluetoothSettings();
    }

    await LocationUtils.enableLocation();

    final Map<String, String> map = {};
    await for (final d
        in _flutterBlue.scan(timeout: const Duration(seconds: 10))) {
      if (d.device.name.toLowerCase().contains("polar h")) {
        map.putIfAbsent(d.device.name, d.device.id.toString);
      }
    }
    return map;
  }

  void startHeartRateStream() {
    if (_heartRateSubscription == null) {
      _heartRateSubscription = _polar.heartRateStream.listen(_onHeartRateEvent);
      _polar.connectToDevice(_deviceId);
    }
  }

  void stopHeartRateStream() {
    _heartRateSubscription?.cancel();
    _polar.disconnectFromDevice(_deviceId);
  }

  bool get enabled => _heartRateSubscription != null;
}
