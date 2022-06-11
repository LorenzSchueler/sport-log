import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class HeartRateUtils extends ChangeNotifier {
  HeartRateUtils();

  static final _polar = Polar();
  static final FlutterBlue _flutterBlue = FlutterBlue.instance;

  static const searchDuration = Duration(seconds: 10);

  bool isSearching = false;
  Map<String, String> devices = {};
  String? deviceId;
  void Function(PolarHeartRateEvent)? onHeartRateEvent;

  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _batterySubscription;

  int? _hr;
  int? get hr => _hr;
  int? _battery;
  int? get battery => _battery;

  @override
  void dispose() {
    stopHeartRateStream();
    super.dispose();
  }

  Future<void> searchDevices() async {
    isSearching = true;
    notifyListeners();
    while (!await _flutterBlue.isOn) {
      final ignore = await showSystemSettingsDialog(
        text:
            "In order to discover heart rate monitors bluetooth must be enabled.",
      );
      if (ignore) {
        return;
      }
      await AppSettings.openBluetoothSettings();
    }

    if (!await LocationUtils.enableLocation()) {
      return;
    }

    devices = {
      await for (final d in _flutterBlue
          .scan(timeout: searchDuration)
          .where((d) => d.device.name.toLowerCase().contains("polar h")))
        d.device.name: d.device.id.toString()
    };

    deviceId = devices.values.firstOrNull;
    isSearching = false;
    notifyListeners();
  }

  void reset() {
    devices = {};
    deviceId = null;
    notifyListeners();
  }

  bool get canStartStream => deviceId != null;

  bool startHeartRateStream() {
    if (deviceId == null) {
      return false;
    }

    if (_heartRateSubscription == null) {
      _heartRateSubscription = _polar.heartRateStream.listen((event) {
        _hr = event.data.hr;
        onHeartRateEvent?.call(event);
        notifyListeners();
      });
      _batterySubscription = _polar.batteryLevelStream.listen((event) {
        _battery = event.level;
        notifyListeners();
      });
      _polar.connectToDevice(deviceId!);
      notifyListeners();
    }
    return true;
  }

  void stopHeartRateStream() {
    _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    _batterySubscription?.cancel();
    _batterySubscription = null;
    if (deviceId != null) {
      _polar.disconnectFromDevice(deviceId!);
    }
    deviceId = null;
    _hr = null;
    _battery = null;
    notifyListeners();
  }

  bool get isActive => _heartRateSubscription != null;
}
