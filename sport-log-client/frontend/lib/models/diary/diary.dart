
import 'package:json_annotation/json_annotation.dart';

part 'diary.g.dart';

@JsonSerializable()
class Diary {
  Diary({
    required this.id,
    required this.userId,
    required this.date,
    required this.bodyweight,
    required this.comments,
  });

  int id;
  int userId;
  DateTime date;
  double? bodyweight;
  String? comments;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryToJson(this);
}