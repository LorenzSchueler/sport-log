// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerVersionString _$ServerVersionStringFromJson(Map<String, dynamic> json) =>
    _ServerVersionString(
      min: json['min'] as String,
      max: json['max'] as String,
    );

Map<String, dynamic> _$ServerVersionStringToJson(
  _ServerVersionString instance,
) => <String, dynamic>{'min': instance.min, 'max': instance.max};

UpdateInfo _$UpdateInfoFromJson(Map<String, dynamic> json) =>
    UpdateInfo(newVersion: json['new_version'] as bool);

Map<String, dynamic> _$UpdateInfoToJson(UpdateInfo instance) =>
    <String, dynamic>{'new_version': instance.newVersion};
