import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:yaml/yaml.dart';

part 'config.g.dart';

@JsonSerializable()
class Config extends JsonSerializable {
  Config({
    required this.accessToken,
    required this.serverAddress,
    required this.deleteDatabase,
    required this.minLogLevel,
    required this.outputRequestJson,
    required this.outputRequestHeaders,
    required this.outputResponseJson,
    required this.outputDbStatement,
  });

  static late final Config instance;

  static Future<void> init() async {
    try {
      final map = (isTest
              ? loadYaml(File("./sport-log-client.yaml").readAsStringSync())
              : loadYaml(await rootBundle.loadString('sport-log-client.yaml')))
          as YamlMap;

      if (kReleaseMode) {
        instance = Config.fromJson(map["release"]! as Map<String, dynamic>);
      } else if (kProfileMode) {
        instance = Config.fromJson(map["profile"]! as Map<String, dynamic>);
      } else {
        instance =
            Config.fromJson((map["debug"]! as YamlMap).cast<String, dynamic>());
      }
    } on YamlException catch (e) {
      _logger.i("sport-log-client.yaml is not a valid YAML file: $e");
      exit(1);
    } on MissingRequiredKeysException catch (e) {
      _logger
          .i("sport-log-client.yaml does not contain keys: ${e.missingKeys}");
      exit(1);
    } on TypeError catch (e) {
      _logger.i(
        "sport-log-client.yaml has a invalid format or contains invalid datatypes for some fields: $e",
      );
      exit(1);
    } catch (e) {
      _logger.i("sport-log-client.yaml could not be parsed: $e");
      exit(1);
    }

    final bool isAndroidEmulator;
    if (isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final _isPhysicalDevice = androidInfo.isPhysicalDevice;
      isAndroidEmulator = _isPhysicalDevice != null && !_isPhysicalDevice;
    } else {
      isAndroidEmulator = false;
    }
    instance.isAndroidEmulator = isAndroidEmulator;

    _logger
      ..i('Min log level: ${instance.minLogLevel}')
      ..i('Delete database: ${instance.deleteDatabase}')
      ..i('Output request json: ${instance.outputRequestJson}')
      ..i('Output request headers: ${instance.outputRequestHeaders}')
      ..i('Output response json: ${instance.outputResponseJson}')
      ..i('Output db statement: ${instance.outputDbStatement}');
  }

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ConfigToJson(this);

  @JsonKey(required: true)
  final String accessToken;
  @JsonKey(defaultValue: "")
  final String serverAddress;
  @JsonKey(defaultValue: Level.nothing)
  final Level minLogLevel;
  @JsonKey(defaultValue: false)
  final bool deleteDatabase;
  @JsonKey(defaultValue: false)
  final bool outputRequestJson;
  @JsonKey(defaultValue: false)
  final bool outputRequestHeaders;
  @JsonKey(defaultValue: false)
  final bool outputResponseJson;
  @JsonKey(defaultValue: false)
  final bool outputDbStatement;
  @JsonKey(ignore: true)
  late final bool isAndroidEmulator;

  static const String databaseName = 'database.sqlite';

  static bool get isTest => Platform.environment.containsKey('FLUTTER_TEST');
  static const bool isWeb = kIsWeb;
  static bool isAndroid = Platform.isAndroid;
  static bool isIOS = Platform.isIOS;
  static bool isLinux = Platform.isLinux;
  static bool isWindows = Platform.isWindows;

  static final _logger = InitLogger('Config');
}
