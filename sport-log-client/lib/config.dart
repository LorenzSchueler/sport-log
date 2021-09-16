import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:logger/logger.dart' as l;

final _logger = Logger('CONFIG');

abstract class Config {
  static late String apiUrlBase;

  static Future<void> init() async {
    // this is only for convenience; should be remove later
    if (await isAndroidEmulator) {
      apiUrlBase = "http://10.0.2.2:8000";
    } else if (isAndroid) {
      apiUrlBase = "http://192.168.0.169:8000";
    } else {
      apiUrlBase = "http://127.0.0.1:8000";
    }
    _logger.i('Clean start: $doCleanStart');
    _logger.i('Generate text data: $generateTestData');
    if (loggedInStart) {
      _logger.w('Logged in at start: $loggedInStart');
    } else {
      _logger.i('Logged in at start: $loggedInStart');
    }
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

  static const bool generateTestData = doCleanStart && true;

  // workaround to not having a connection to server on real device;
  // sets user1 (user1-passwd) as current user
  static const bool loggedInStart = true;

  static l.Level minLogLevel = l.Level.debug;
}
