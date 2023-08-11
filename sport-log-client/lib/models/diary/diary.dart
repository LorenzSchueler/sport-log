import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

part 'diary.g.dart';

@JsonSerializable()
class Diary extends AtomicEntity {
  Diary({
    required this.id,
    required this.date,
    required this.bodyweight,
    required this.comments,
    required this.deleted,
  });

  Diary.defaultValue()
      : id = randomId(),
        date = DateTime.now(),
        bodyweight = null,
        comments = null,
        deleted = false;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @JsonKey(includeToJson: true, name: "user_id")
  @IdConverter()
  Int64 get _userId => Settings.instance.userId!;
  @DateConverter()
  DateTime date;
  double? bodyweight;
  String? comments;
  @override
  bool deleted;

  @override
  Map<String, dynamic> toJson() => _$DiaryToJson(this);

  @override
  Diary clone() => Diary(
        id: id.clone(),
        date: date.clone(),
        bodyweight: bodyweight,
        comments: comments,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, "Diary: deleted == true") &&
        validate(
          bodyweight == null || bodyweight! >= 0,
          'Diary: bodyweight < 0',
        ) &&
        validate(
          bodyweight != null && bodyweight! > 0 ||
              comments != null && comments!.isNotEmpty,
          'Diary: bodyweight and comments are null',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          bodyweight == null || bodyweight! > 0,
          'Diary: bodyweight <= 0',
        ) &&
        validate(
          comments == null || comments!.isNotEmpty,
          'Diary: comments are empty but not null',
        ) &&
        validate(
          bodyweight != null && bodyweight! > 0 ||
              comments != null && comments!.isNotEmpty,
          'Diary: bodyweight and comments are null',
        );
  }

  @override
  void sanitize() {
    if (bodyweight != null && bodyweight! <= 0) {
      bodyweight = null;
    }
    if (comments != null && comments!.isEmpty) {
      comments = null;
    }
  }
}

class DbDiarySerializer extends DbSerializer<Diary> {
  @override
  Diary fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Diary(
      id: Int64(r[prefix + Columns.id]! as int),
      date: const DateConverter().fromJson(r[prefix + Columns.date]! as String),
      bodyweight: r[prefix + Columns.bodyweight] as double?,
      comments: r[prefix + Columns.comments] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Diary o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.date: const DateConverter().toJson(o.date),
      Columns.bodyweight: o.bodyweight,
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
