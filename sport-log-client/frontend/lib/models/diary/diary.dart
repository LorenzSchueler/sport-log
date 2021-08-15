
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/helpers/update_validatable.dart';

part 'diary.g.dart';

@JsonSerializable()
class Diary extends Insertable implements UpdateValidatable {
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

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return DiariesCompanion(
      id: Value(id),
      userId: Value(userId),
      date: Value(date),
      bodyweight: Value(bodyweight),
      comments: Value(comments),
      deleted: Value(deleted),
    ).toColumns(false);
  }

  @override
  bool validateOnUpdate() {
    return (bodyweight == null || bodyweight! > 0)
        && !deleted;
  }
}