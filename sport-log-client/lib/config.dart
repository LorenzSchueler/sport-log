import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

abstract class Config {
  static late String apiUrlBase;

  static Future<void> init() async {
    // this is only for convenience; should be remove later
    apiUrlBase = await isAndroidEmulator
        ? "http://10.0.2.2:8000"
        : "http://127.0.0.1:8000";
  }

  static bool get isWeb => kIsWeb;
  // Workaround for Platform.XXX not being supported on web
  static bool get isAndroid => !isWeb && Platform.isAndroid;
  static bool get isIOS => !isWeb && Platform.isIOS;
  static bool get isLinux => !isWeb && Platform.isLinux;

  static Future<bool> get isAndroidEmulator async {
    if (isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final _isPhysicalDevice = androidInfo.isPhysicalDevice;
      return _isPhysicalDevice != null && !_isPhysicalDevice;
    }
    return false;
  }

  static int debugApiDelay = 500; // ms

  static String databaseName = 'database.sqlite';
}
