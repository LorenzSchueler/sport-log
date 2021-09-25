import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'metcon_session.g.dart';

@JsonSerializable()
class MetconSession implements DbObject {
  MetconSession({
    required this.id,
    required this.userId,
    required this.metconId,
    required this.datetime,
    required this.time,
    required this.rounds,
    required this.reps,
    required this.rx,
    required this.comments,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
  @IdConverter()
  Int64 metconId;
  @DateTimeConverter()
  DateTime datetime;
  int? time;
  int? rounds;
  int? reps;
  bool rx;
  String? comments;
  @override
  bool deleted;

  factory MetconSession.fromJson(Map<String, dynamic> json) =>
      _$MetconSessionFromJson(json);

  Map<String, dynamic> toJson() => _$MetconSessionToJson(this);

  @override
  bool isValid() {
    return validate(deleted != true, 'MetconSession: deleted == true') &&
        validate(time == null || time! > 0, 'MetconSession: time <= 0') &&
        validate(rounds == null || rounds! > 0, 'MetconSession: rounds <= 0') &&
        validate(reps == null || reps! > 0, 'MetconSession: reps <= 0');
  }
}

class DbMetconSessionSerializer implements DbSerializer<MetconSession> {
  @override
  MetconSession fromDbRecord(DbRecord r, {String prefix = ''}) {
    return MetconSession(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      metconId: Int64(r[Keys.metconId]! as int),
      datetime: DateTime.parse(r[Keys.datetime]! as String),
      time: r[Keys.time] as int?,
      rounds: r[Keys.rounds] as int?,
      reps: r[Keys.reps] as int?,
      rx: r[Keys.rx]! as int == 1,
      comments: r[Keys.comments] as String?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(MetconSession o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.metconId: o.metconId.toInt(),
      Keys.datetime: o.datetime.toString(),
      Keys.time: o.time,
      Keys.rounds: o.rounds,
      Keys.reps: o.reps,
      Keys.rx: o.rx ? 1 : 0,
      Keys.comments: o.comments,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
