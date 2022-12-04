import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/settings.dart';

part 'metcon_session.g.dart';

@JsonSerializable()
class MetconSession extends AtomicEntity {
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

  factory MetconSession.defaultValue(Metcon metcon) {
    Duration? time;
    int? rounds;
    int? reps;
    switch (metcon.metconType) {
      case MetconType.amrap:
        rounds = 0;
        reps = 0;
        break;
      case MetconType.emom:
        break;
      case MetconType.forTime:
        time = Duration.zero;
        break;
    }
    return MetconSession(
      id: randomId(),
      userId: Settings.instance.userId!,
      metconId: metcon.id,
      datetime: DateTime.now(),
      time: time,
      rounds: rounds,
      reps: reps,
      rx: true,
      comments: null,
      deleted: false,
    );
  }

  factory MetconSession.fromJson(Map<String, dynamic> json) =>
      _$MetconSessionFromJson(json);

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

  @override
  Map<String, dynamic> toJson() => _$MetconSessionToJson(this);

  @override
  MetconSession clone() => MetconSession(
        id: id.clone(),
        userId: userId.clone(),
        metconId: metconId.clone(),
        datetime: datetime.clone(),
        time: time?.clone(),
        rounds: rounds,
        reps: reps,
        rx: rx,
        comments: comments,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'MetconSession: deleted == true') &&
        validate(
          time == null || time! > Duration.zero,
          'MetconSession: time <= 0',
        ) &&
        validate(rounds == null || rounds! >= 0, 'MetconSession: rounds < 0') &&
        validate(reps == null || reps! >= 0, 'MetconSession: reps < 0');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          comments == null || comments!.isNotEmpty,
          'MetconSession: comments are empty but not null',
        );
  }

  @override
  void sanitize() {
    if (comments != null && comments!.isEmpty) {
      comments = null;
    }
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
          : Duration(milliseconds: r[prefix + Columns.time]! as int),
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
      Columns.time: o.time?.inMilliseconds,
      Columns.rounds: o.rounds,
      Columns.reps: o.reps,
      Columns.rx: o.rx ? 1 : 0,
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
