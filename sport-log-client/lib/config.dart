import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/server_version/server_version.dart';
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

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  static late final Config _instance;
  static Config get instance => _instance;

  static Future<void> init() async {
    try {
      final map = (isTest
              ? loadYaml(File("./sport-log-client.yaml").readAsStringSync())
              : loadYaml(await rootBundle.loadString('sport-log-client.yaml')))
          as YamlMap;

      final instance = releaseMode
          ? map["release"]! as YamlMap
          : profileMode
              ? map["profile"]! as YamlMap
              : map["debug"]! as YamlMap;
      _instance = Config.fromJson(instance.cast<String, dynamic>());
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
      final isPhysicalDevice = androidInfo.isPhysicalDevice;
      isAndroidEmulator = isPhysicalDevice != null && !isPhysicalDevice;
    } else {
      isAndroidEmulator = false;
    }
    instance.isAndroidEmulator = isAndroidEmulator;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    instance.version = Version.fromString(
      isTest ? "0.1.0" : packageInfo.version,
    );

    _logger
      ..i('Min log level: ${instance.minLogLevel}')
      ..i('Delete database: ${instance.deleteDatabase}')
      ..i('Output request json: ${instance.outputRequestJson}')
      ..i('Output request headers: ${instance.outputRequestHeaders}')
      ..i('Output response json: ${instance.outputResponseJson}')
      ..i('Output db statement: ${instance.outputDbStatement}');
  }

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
  @JsonKey(ignore: true)
  late final Version version;

  static final Version apiVersion = Version(0, 2);
  static const String databaseName = 'database.sqlite';
  static const String hiveBoxName = 'settings';
  static const Duration httpTimeout = Duration(seconds: 20);

  static const bool isWeb = kIsWeb;
  static bool isAndroid = Platform.isAndroid;
  static bool isIOS = Platform.isIOS;
  static bool isLinux = Platform.isLinux;
  static bool isWindows = Platform.isWindows;

  static bool get isTest => Platform.environment.containsKey('FLUTTER_TEST');

  static const bool releaseMode = kReleaseMode;
  static const bool profileMode = kProfileMode;
  static const bool debugMode = kDebugMode;

  static final _logger = InitLogger('Config');
}
