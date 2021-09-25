import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'diary.g.dart';

@JsonSerializable()
class Diary implements DbObject {
  Diary({
    required this.id,
    required this.userId,
    required this.date,
    required this.bodyweight,
    required this.comments,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
  @DateConverter()
  DateTime date;
  double? bodyweight;
  String? comments;
  @override
  bool deleted;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryToJson(this);

  @override
  bool isValid() {
    return validate(
            bodyweight == null || bodyweight! > 0, 'Diary: bodyweight <= 0') &&
        validate(!deleted, 'Diary: deleted == true');
  }
}

class DbDiarySerializer implements DbSerializer<Diary> {
  @override
  Diary fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Diary(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      date: const DateConverter().fromJson(r[Keys.date]! as String),
      bodyweight: r[Keys.bodyweight] as double?,
      comments: r[Keys.comments] as String?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Diary o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.date: const DateConverter().toJson(o.date),
      Keys.bodyweight: o.bodyweight,
      Keys.comments: o.comments,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
