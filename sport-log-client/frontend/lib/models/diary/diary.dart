
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/json_serialization.dart';

part 'diary.g.dart';

@JsonSerializable()
class Diary {
  Diary({
    required this.id,
    required this.userId,
    required this.date,
    required this.bodyweight,
    required this.comments,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  DateTime date;
  double? bodyweight;
  String? comments;
  bool deleted;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryToJson(this);
}