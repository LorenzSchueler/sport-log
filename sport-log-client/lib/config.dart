import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:logger/logger.dart' as l;

final _logger = Logger('CONFIG');

abstract class Config {
  static late final String apiUrlBase;
  static late final bool deleteDatabase;
  static late final bool generateTestData;
  static const l.Level minLogLevel = l.Level.debug;

  // this is only an approximate value (due to limitations of timer)
  static const syncInterval = Duration(minutes: 1);

  static Future<void> init() async {
    const String defaultAddress = "127.0.0.1:8000";
    if (await isAndroidEmulator) {
      apiUrlBase = "http://10.0.2.2:8000";
    } else if (isAndroid || isIOS) {
      const address = String.fromEnvironment("PHONE_SERVER_ADDRESS",
          defaultValue: defaultAddress);
      apiUrlBase = "http://$address";
    } else {
      const address = String.fromEnvironment("LOCAL_SERVER_ADDRESS",
          defaultValue: defaultAddress);
      apiUrlBase = "http://$address";
    }

    const deleteDatabaseEnvVar =
        String.fromEnvironment("DELETE_DATABASE", defaultValue: "false");
    deleteDatabase = deleteDatabaseEnvVar.toLowerCase() == "true";

    const generateTestDataEnvVar =
        String.fromEnvironment("GENERATE_TEST_DATA", defaultValue: "false");
    generateTestData = generateTestDataEnvVar.toLowerCase() == "true";

    _logger.i('Server url: $apiUrlBase');
    _logger.i('Delete database: $deleteDatabase');
    _logger.i('Generate test data: $generateTestData');
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
}
