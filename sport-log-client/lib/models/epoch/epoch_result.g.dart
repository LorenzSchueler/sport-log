// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epoch_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpochResult _$EpochResultFromJson(Map<String, dynamic> json) => EpochResult(
      epoch: const IdConverter().fromJson(json['epoch'] as String),
    );

Map<String, dynamic> _$EpochResultToJson(EpochResult instance) =>
    <String, dynamic>{
      'epoch': const IdConverter().toJson(instance.epoch),
    };
