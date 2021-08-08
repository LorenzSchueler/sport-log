// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Diary _$DiaryFromJson(Map<String, dynamic> json) => Diary(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      date: DateTime.parse(json['date'] as String),
      bodyweight: (json['bodyweight'] as num?)?.toDouble(),
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$DiaryToJson(Diary instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'date': instance.date.toIso8601String(),
      'bodyweight': instance.bodyweight,
      'comments': instance.comments,
    };

NewDiary _$NewDiaryFromJson(Map<String, dynamic> json) => NewDiary(
      userId: json['user_id'] as int,
      date: DateTime.parse(json['date'] as String),
      bodyweight: (json['bodyweight'] as num?)?.toDouble(),
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$NewDiaryToJson(NewDiary instance) => <String, dynamic>{
      'user_id': instance.userId,
      'date': instance.date.toIso8601String(),
      'bodyweight': instance.bodyweight,
      'comments': instance.comments,
    };
