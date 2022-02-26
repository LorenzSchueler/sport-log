import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'metcon_session.g.dart';

@JsonSerializable()
class MetconSession extends AtomicEntity {
  // JsonConvertable<MetconSession> {
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
  @OptionalDurationConverter()
  Duration? time;
  int? rounds;
  int? reps;
  bool rx;
  String? comments;
  @override
  bool deleted;

  factory MetconSession.fromJson(Map<String, dynamic> json) =>
      _$MetconSessionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetconSessionToJson(this);

  @override
  bool isValid() {
    return validate(deleted != true, 'MetconSession: deleted == true') &&
        validate(
          time == null || time!.inSeconds > 0,
          'MetconSession: time <= 0',
        ) &&
        validate(rounds == null || rounds! > 0, 'MetconSession: rounds <= 0') &&
        validate(reps == null || reps! > 0, 'MetconSession: reps <= 0');
  }
}

class DbMetconSessionSerializer extends DbSerializer<MetconSession> {
  @override
  MetconSession fromDbRecord(DbRecord r, {String prefix = ''}) {
    return MetconSession(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
      metconId: Int64(r[prefix + Columns.metconId]! as int),
      datetime: DateTime.parse(r[prefix + Columns.datetime]! as String),
      time: r[prefix + Columns.time] == null
          ? null
          : Duration(seconds: r[prefix + Columns.time]! as int),
      rounds: r[prefix + Columns.rounds] as int?,
      reps: r[prefix + Columns.reps] as int?,
      rx: r[prefix + Columns.rx]! as int == 1,
      comments: r[prefix + Columns.comments] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(MetconSession o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId.toInt(),
      Columns.metconId: o.metconId.toInt(),
      Columns.datetime: o.datetime.toString(),
      Columns.time: o.time?.inSeconds,
      Columns.rounds: o.rounds,
      Columns.reps: o.reps,
      Columns.rx: o.rx ? 1 : 0,
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
