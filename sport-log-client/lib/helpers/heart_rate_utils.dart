import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class HeartRateUtils extends ChangeNotifier {
  static final _polar = Polar();

  static const _searchDuration = Duration(seconds: 10);

  bool _isSearching = false;
  bool get isSearching => _isSearching;
  Map<String, String> _devices = {};
  Map<String, String> get devices => _devices;
  String? deviceId;

  StreamSubscription<PolarHeartRateEvent>? _heartRateSubscription;
  StreamSubscription<PolarBatteryLevelEvent>? _batterySubscription;

  int? _hr;
  int? get hr => _hr;
  int? _battery;
  int? get battery => _battery;

  bool _disposed = false;

  bool get canStartStream => deviceId != null;

  bool get isActive => _heartRateSubscription != null;

  @override
  void dispose() {
    _disposed = true;
    stopHeartRateStream();
    super.dispose();
  }

  Future<void> searchDevices() async {
    _isSearching = true;
    notifyListeners();

    await stopHeartRateStream();

    while (!await FlutterBluePlus.instance.isOn) {
      final ignore =
          await showSystemSettingsDialog(text: "Please enable bluetooth.");
      if (ignore) {
        return;
      }
    }

    _devices = {
      await for (final d in _polar.searchForDevice().timeout(
            _searchDuration,
            onTimeout: (sink) => sink.close(),
          ))
        d.name: d.deviceId
    };

    deviceId = devices.values.firstOrNull;
    _isSearching = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  void reset() {
    _devices = {};
    deviceId = null;
    notifyListeners();
  }

  Future<bool> startHeartRateStream(
    void Function(PolarHeartRateEvent)? onHeartRateEvent,
  ) async {
    if (deviceId == null || _heartRateSubscription != null) {
      return false;
    }
    _heartRateSubscription = _polar.heartRateStream.listen((event) {
      _hr = event.data.hr;
      onHeartRateEvent?.call(event);
      notifyListeners();
    });
    _batterySubscription = _polar.batteryLevelStream.listen((event) {
      _battery = event.level;
      notifyListeners();
    });
    await _polar.connectToDevice(deviceId!);
    notifyListeners();
    return true;
  }

  Future<void> stopHeartRateStream() async {
    await _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    await _batterySubscription?.cancel();
    _batterySubscription = null;
    if (deviceId != null) {
      await _polar.disconnectFromDevice(deviceId!);
    }
    deviceId = null;
    _hr = null;
    _battery = null;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
