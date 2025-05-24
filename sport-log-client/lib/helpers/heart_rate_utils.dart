import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/helpers/request_permission.dart';

class HeartRateUtils extends ChangeNotifier {
  static final _polar = Polar();

  static const _searchDuration = Duration(seconds: 10);

  bool _isSearching = false;
  bool get isSearching => _isSearching;
  Map<String, String> _devices = {};
  Map<String, String> get devices => _devices;
  String? deviceId;

  StreamSubscription<PolarStreamingData<PolarHrSample>>? _heartRateSubscription;
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

  bool get canConnect => deviceId != null;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _heartRateSubscription != null;
  bool get isNotConnected => !isConnected;
  bool get isWaiting => (isConnecting || isConnected) && _hr == null;

  @override
  void dispose() {
    _disposed = true;
    stopHeartRateStream();
    super.dispose();
  }

  Future<bool> requestPermissions() async {
    // polar can request permissions but does not provide the permission status

    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    assert(sdkInt >= 23);
    if (sdkInt < 31) {
      // If we are on an Android version before S
      return PermissionRequest.request(Permission.location);
    } else {
      // If we are on Android S+
      if (!await PermissionRequest.request(Permission.bluetoothScan)) {
        return false;
      }
      return PermissionRequest.request(Permission.bluetoothConnect);
    }
  }

  Future<bool> enableBluetooth() {
    return Request.request(
      title: "Bluetooth Required",
      text: "Please enable bluetooth.",
      check: () async =>
          (await FlutterBluePlus.adapterState.first) ==
          BluetoothAdapterState.on,
      change: () async {
        try {
          await FlutterBluePlus.turnOn();
        } on FlutterBluePlusException catch (e) {
          if (e.code != FbpErrorCode.userRejected.index &&
              e.code != FbpErrorCode.timeout.index) {
            rethrow;
          }
        }
      },
    );
  }

  // ignore: long-method
  Future<void> searchDevices() async {
    if (_isSearching) {
      return;
    }

    _isSearching = true;
    notifyListeners();

    await stopHeartRateStream();

    await requestPermissions();
    if (!await enableBluetooth()) {
      _isSearching = false;
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }

    _devices = {
      await for (final d in _polar.searchForDevice().timeout(
        _searchDuration,
        onTimeout: (sink) => sink.close(),
      ))
        d.name: d.deviceId,
    };

    deviceId = devices.values.firstOrNull; // auto select first one
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
    void Function(List<int>)? onHeartRateEvent, {
    bool hrv = false,
  }) async {
    if (!canConnect || isConnecting || isConnected) {
      return false;
    }

    _isConnecting = true;
    notifyListeners();

    await _polar.connectToDevice(deviceId!);
    await _polar.sdkFeatureReady.firstWhere(
      (e) => e.identifier == deviceId && e.feature == PolarSdkFeature.hr,
    );

    _heartRateSubscription = _polar
        .startHrStreaming(deviceId!)
        .listen(
          (e) {
            final samples = e.samples;
            if (samples.isEmpty) {
              return;
            }
            _hr = samples.last.hr;
            final rrs = <int>[];
            for (final sample in samples) {
              rrs.addAll(sample.rrsMs);
            }
            if (hrv) {
              _rrs.addAll(rrs);
              _setHrv();
            }

            onHeartRateEvent?.call(rrs);
            if (!_disposed) {
              notifyListeners();
            }
          },
          onError: (Object error) {
            if (error is PlatformException) {
              stopHeartRateStream();
            }
          },
        );
    _batterySubscription = _polar.batteryLevel.listen((event) {
      _battery = event.level;
      if (!_disposed) {
        notifyListeners();
      }
    });

    _isConnecting = false;
    if (!_disposed) {
      notifyListeners();
    }
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
