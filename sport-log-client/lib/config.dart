import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:logger/logger.dart' as l;

final _logger = Logger('CONFIG');

abstract class Config {
  static late final bool deleteDatabase;
  static late final bool generateTestData;
  static late final l.Level minLogLevel;
  static late final bool outputRequestJson;
  static late final bool outputRequestHeaders;
  static late final bool outputResponseJson;
  static late final bool outputDbStatement;

  static Future<void> init() async {
    deleteDatabase =
        (dotenv.env['DELETE_DATABASE'] ?? "").parseBool(defaultValue: false);

    generateTestData =
        (dotenv.env['GENERATE_TEST_DATA'] ?? "").parseBool(defaultValue: false);

    final logLevelStr = dotenv.env['LOG_LEVEL'] ?? '';
    switch (logLevelStr.toUpperCase()) {
      case 'VERBOSE':
        minLogLevel = l.Level.verbose;
        break;
      case 'DEBUG':
        minLogLevel = l.Level.debug;
        break;
      case 'INFO':
        minLogLevel = l.Level.info;
        break;
      case 'WARNING':
        minLogLevel = l.Level.warning;
        break;
      case 'Error':
        minLogLevel = l.Level.error;
        break;
      case 'WTF':
        minLogLevel = l.Level.wtf;
        break;
      case 'NOTHING':
        minLogLevel = l.Level.nothing;
        break;
      default:
        minLogLevel = l.Level.debug;
    }

    outputRequestJson = (dotenv.env['OUTPUT_REQUEST_JSON'] ?? "")
        .parseBool(defaultValue: false);

    outputRequestHeaders = (dotenv.env['OUTPUT_REQUEST_HEADERS'] ?? "")
        .parseBool(defaultValue: false);

    outputResponseJson = (dotenv.env['OUTPUT_RESPONSE_JSON'] ?? "")
        .parseBool(defaultValue: false);

    outputDbStatement = (dotenv.env['OUTPUT_DB_STATEMENT'] ?? "")
        .parseBool(defaultValue: false);

    _logger.i('Delete database: $deleteDatabase');
    _logger.i('Generate test data: $generateTestData');
    _logger.i('Min log level: $minLogLevel');
    _logger.i('Output request json: $outputRequestJson');
    _logger.i('Output request headers: $outputRequestHeaders');
    _logger.i('Output response json: $outputResponseJson');
    _logger.i('Output db statement: $outputDbStatement');
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
