import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

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
  List<int> _rrs = [];
  //https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5624990/
  int? _hrv;
  int? get hrv => _hrv;
  void _setHrv() {
    if (_rrs.length < 2) {
      _hrv = null;
      return;
    }
    var sumOfSquares = 0;
    for (var i = 0; i < _rrs.length - 1; i++) {
      sumOfSquares += pow(_rrs[i] - _rrs[i + 1], 2) as int;
    }

    _hrv = sqrt(sumOfSquares / (_rrs.length - 1)).round();
  }

  bool _disposed = false;

  bool get canStartStream => deviceId != null;

  bool get isWaiting => isActive && _hr == null;
  bool get isActive => _heartRateSubscription != null;
  bool get isNotActive => _heartRateSubscription == null;

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
      final systemSettings =
          await showSystemSettingsDialog(text: "Please enable bluetooth.");
      if (systemSettings.isIgnore) {
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
    void Function(PolarHeartRateEvent)? onHeartRateEvent, {
    bool hrv = false,
  }) async {
    if (deviceId == null || _heartRateSubscription != null) {
      return false;
    }
    _heartRateSubscription = _polar.heartRateStream.listen((event) {
      _hr = event.data.hr;
      if (hrv) {
        _rrs.addAll(event.data.rrsMs);
        _setHrv();
      }
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
    _rrs = [];
    _hrv = null;
    _battery = null;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
