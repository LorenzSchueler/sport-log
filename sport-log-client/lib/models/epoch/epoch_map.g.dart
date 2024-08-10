// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epoch_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpochMap _$EpochMapFromJson(Map<String, dynamic> json) => EpochMap(
      user: const IdConverter().fromJson(json['user'] as String),
      diary: const IdConverter().fromJson(json['diary'] as String),
      wod: const IdConverter().fromJson(json['wod'] as String),
      movement: const IdConverter().fromJson(json['movement'] as String),
      strengthSession:
          const IdConverter().fromJson(json['strength_session'] as String),
      strengthSet: const IdConverter().fromJson(json['strength_set'] as String),
      metcon: const IdConverter().fromJson(json['metcon'] as String),
      metconSession:
          const IdConverter().fromJson(json['metcon_session'] as String),
      metconMovement:
          const IdConverter().fromJson(json['metcon_movement'] as String),
      cardioSession:
          const IdConverter().fromJson(json['cardio_session'] as String),
      route: const IdConverter().fromJson(json['route'] as String),
      platform: const IdConverter().fromJson(json['platform'] as String),
      platformCredential:
          const IdConverter().fromJson(json['platform_credential'] as String),
      actionProvider:
          const IdConverter().fromJson(json['action_provider'] as String),
      action: const IdConverter().fromJson(json['action'] as String),
      actionRule: const IdConverter().fromJson(json['action_rule'] as String),
      actionEvent: const IdConverter().fromJson(json['action_event'] as String),
    );

Map<String, dynamic> _$EpochMapToJson(EpochMap instance) => <String, dynamic>{
      'user': const IdConverter().toJson(instance.user),
      'diary': const IdConverter().toJson(instance.diary),
      'wod': const IdConverter().toJson(instance.wod),
      'movement': const IdConverter().toJson(instance.movement),
      'strength_session': const IdConverter().toJson(instance.strengthSession),
      'strength_set': const IdConverter().toJson(instance.strengthSet),
      'metcon': const IdConverter().toJson(instance.metcon),
      'metcon_session': const IdConverter().toJson(instance.metconSession),
      'metcon_movement': const IdConverter().toJson(instance.metconMovement),
      'cardio_session': const IdConverter().toJson(instance.cardioSession),
      'route': const IdConverter().toJson(instance.route),
      'platform': const IdConverter().toJson(instance.platform),
      'platform_credential':
          const IdConverter().toJson(instance.platformCredential),
      'action_provider': const IdConverter().toJson(instance.actionProvider),
      'action': const IdConverter().toJson(instance.action),
      'action_rule': const IdConverter().toJson(instance.actionRule),
      'action_event': const IdConverter().toJson(instance.actionEvent),
    };
