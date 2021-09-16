import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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

  static const String databaseName = 'database.sqlite';

  // if true, the database will be deleted and re-created,
  // and the account data will be fetched completely;
  // should be false normally
  static const bool doCleanStart = true;

  static const bool generateTestData = doCleanStart && false;

  static Level minLogLevel = Level.debug;
}
