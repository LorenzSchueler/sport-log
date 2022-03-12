// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConflictDescriptor _$ConflictDescriptorFromJson(Map<String, dynamic> json) =>
    ConflictDescriptor(
      table: json['table'] as String,
      columns:
          (json['columns'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ConflictDescriptorToJson(ConflictDescriptor instance) =>
    <String, dynamic>{
      'table': instance.table,
      'columns': instance.columns,
    };

ErrorMessage _$ErrorMessageFromJson(Map<String, dynamic> json) => ErrorMessage(
      status: json['status'] as int,
      message: (json['message'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ConflictDescriptor.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ErrorMessageToJson(ErrorMessage instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
    };
