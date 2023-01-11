import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'strength_session.g.dart';

@JsonSerializable()
class StrengthSession extends AtomicEntity {
  StrengthSession({
    required this.id,
    required this.userId,
    required this.datetime,
    required this.movementId,
    required this.interval,
    required this.comments,
    required this.deleted,
  });

  factory StrengthSession.fromJson(Map<String, dynamic> json) =>
      _$StrengthSessionFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @OptionalIdConverter()
  Int64? strengthBlueprintId;
  @IdConverter()
  Int64 userId;
  @DateTimeConverter()
  DateTime datetime;
  @IdConverter()
  Int64 movementId;
  @OptionalDurationConverter()
  Duration? interval;
  String? comments;
  @override
  bool deleted;

  static const defaultInterval = Duration(seconds: 150);

  @override
  Map<String, dynamic> toJson() => _$StrengthSessionToJson(this);

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'StrengthSession: deleted == true') &&
        validate(
          interval == null || interval! > Duration.zero,
          'StrengthSession: interval <= 0',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          comments == null || comments!.isNotEmpty,
          'StrengthSession: comments are empty but not null',
        );
  }

  @override
  void sanitize() {
    if (comments != null && comments!.isEmpty) {
      comments = null;
    }
  }

  @override
  StrengthSession clone() => StrengthSession(
        id: id.clone(),
        userId: userId.clone(),
        datetime: datetime.clone(),
        movementId: movementId.clone(),
        interval: interval?.clone(),
        comments: comments,
        deleted: deleted,
      );
}

class DbStrengthSessionSerializer extends DbSerializer<StrengthSession> {
  @override
  StrengthSession fromDbRecord(DbRecord r, {String prefix = ''}) {
    return StrengthSession(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
      datetime: DateTime.parse(r[prefix + Columns.datetime]! as String),
      movementId: Int64(r[prefix + Columns.movementId]! as int),
      interval: r[prefix + Columns.interval] == null
          ? null
          : Duration(milliseconds: r[prefix + Columns.interval]! as int),
      comments: r[prefix + Columns.comments] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(StrengthSession o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId.toInt(),
      Columns.datetime: o.datetime.toString(),
      Columns.movementId: o.movementId.toInt(),
      Columns.interval: o.interval?.inMilliseconds,
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
