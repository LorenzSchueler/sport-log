import 'package:flutter/services.dart';
import 'package:sport_log/config.dart';

/// Turns the screen off while the proximity sensor is covered (Android only).
class ProximityWakeLock {
  static const _channel = MethodChannel("org.sport_log/proximity_wake_lock");

  static Future<void> acquire() async {
    if (Config.isAndroid) {
      await _channel.invokeMethod<bool>("acquire");
    }
  }

  static Future<void> release() async {
    if (Config.isAndroid) {
      await _channel.invokeMethod<void>("release");
    }
  }
}
