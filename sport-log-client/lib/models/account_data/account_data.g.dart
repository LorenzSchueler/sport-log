// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountData _$AccountDataFromJson(Map<String, dynamic> json) {
  return AccountData(
    user: json['user'] == null
        ? null
        : User.fromJson(json['user'] as Map<String, dynamic>),
    diaries: (json['diaries'] as List<dynamic>)
        .map((e) => Diary.fromJson(e as Map<String, dynamic>))
        .toList(),
    wods: (json['wods'] as List<dynamic>)
        .map((e) => Wod.fromJson(e as Map<String, dynamic>))
        .toList(),
    movements: (json['movements'] as List<dynamic>)
        .map((e) => Movement.fromJson(e as Map<String, dynamic>))
        .toList(),
    strengthSessions: (json['strenght_sessions'] as List<dynamic>)
        .map((e) => StrengthSession.fromJson(e as Map<String, dynamic>))
        .toList(),
    strengthSets: (json['strenght_set'] as List<dynamic>)
        .map((e) => StrengthSet.fromJson(e as Map<String, dynamic>))
        .toList(),
    metcons: (json['metcons'] as List<dynamic>)
        .map((e) => Metcon.fromJson(e as Map<String, dynamic>))
        .toList(),
    metconSessions: (json['metcon_sessions'] as List<dynamic>)
        .map((e) => MetconSession.fromJson(e as Map<String, dynamic>))
        .toList(),
    metconMovements: (json['metcon_movements'] as List<dynamic>)
        .map((e) => MetconMovement.fromJson(e as Map<String, dynamic>))
        .toList(),
    cardioSessions: (json['cardio_sessions'] as List<dynamic>)
        .map((e) => CardioSession.fromJson(e as Map<String, dynamic>))
        .toList(),
    routes: (json['routes'] as List<dynamic>)
        .map((e) => Route.fromJson(e as Map<String, dynamic>))
        .toList(),
    platforms: (json['platforms'] as List<dynamic>)
        .map((e) => Platform.fromJson(e as Map<String, dynamic>))
        .toList(),
    platformCredentials: (json['platform_credentials'] as List<dynamic>)
        .map((e) => PlatformCredential.fromJson(e as Map<String, dynamic>))
        .toList(),
    actionProviders: (json['action_providers'] as List<dynamic>)
        .map((e) => ActionProvider.fromJson(e as Map<String, dynamic>))
        .toList(),
    actions: (json['actions'] as List<dynamic>)
        .map((e) => Action.fromJson(e as Map<String, dynamic>))
        .toList(),
    actionRules: (json['action_rules'] as List<dynamic>)
        .map((e) => ActionRule.fromJson(e as Map<String, dynamic>))
        .toList(),
    actionEvents: (json['action_event'] as List<dynamic>)
        .map((e) => ActionEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$AccountDataToJson(AccountData instance) =>
    <String, dynamic>{
      'user': instance.user,
      'diaries': instance.diaries,
      'wods': instance.wods,
      'movements': instance.movements,
      'strenght_sessions': instance.strengthSessions,
      'strenght_set': instance.strengthSets,
      'metcons': instance.metcons,
      'metcon_sessions': instance.metconSessions,
      'metcon_movements': instance.metconMovements,
      'cardio_sessions': instance.cardioSessions,
      'routes': instance.routes,
      'platforms': instance.platforms,
      'platform_credentials': instance.platformCredentials,
      'action_providers': instance.actionProviders,
      'actions': instance.actions,
      'action_rules': instance.actionRules,
      'action_event': instance.actionEvents,
    };
