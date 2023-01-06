// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HandlerError _$HandlerErrorFromJson(Map<String, dynamic> json) => HandlerError(
      status: json['status'] as int,
      message: json['message'] == null
          ? null
          : ErrorMessage.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HandlerErrorToJson(HandlerError instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
    };
