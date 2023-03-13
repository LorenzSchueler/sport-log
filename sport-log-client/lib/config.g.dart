// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['access_token'],
  );
  return Config(
    accessToken: json['access_token'] as String,
    serverAddress: json['server_address'] as String? ?? '',
    deleteDatabase: json['delete_database'] as bool? ?? false,
    minLogLevel: $enumDecodeNullable(_$LevelEnumMap, json['min_log_level']) ??
        Level.nothing,
    outputRequestJson: json['output_request_json'] as bool? ?? false,
    outputRequestHeaders: json['output_request_headers'] as bool? ?? false,
    outputResponseJson: json['output_response_json'] as bool? ?? false,
    outputResponseHeaders: json['output_response_headers'] as bool? ?? false,
    outputDbStatement: json['output_db_statement'] as bool? ?? false,
  );
}

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'server_address': instance.serverAddress,
      'min_log_level': _$LevelEnumMap[instance.minLogLevel]!,
      'delete_database': instance.deleteDatabase,
      'output_request_json': instance.outputRequestJson,
      'output_request_headers': instance.outputRequestHeaders,
      'output_response_json': instance.outputResponseJson,
      'output_response_headers': instance.outputResponseHeaders,
      'output_db_statement': instance.outputDbStatement,
    };

const _$LevelEnumMap = {
  Level.verbose: 'verbose',
  Level.debug: 'debug',
  Level.info: 'info',
  Level.warning: 'warning',
  Level.error: 'error',
  Level.wtf: 'wtf',
  Level.nothing: 'nothing',
};
