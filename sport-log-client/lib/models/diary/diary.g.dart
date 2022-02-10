// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Diary _$DiaryFromJson(Map<String, dynamic> json) => Diary(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const IdConverter().fromJson(json['user_id'] as String),
      date: const DateConverter().fromJson(json['date'] as String),
      bodyweight: (json['bodyweight'] as num?)?.toDouble(),
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$DiaryToJson(Diary instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'date': const DateConverter().toJson(instance.date),
      'bodyweight': instance.bodyweight,
      'comments': instance.comments,
      'deleted': instance.deleted,
    };
