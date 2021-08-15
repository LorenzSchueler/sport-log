
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/models/update_validatable.dart';

part 'metcon_session.g.dart';

@JsonSerializable()
class MetconSession extends Insertable<MetconSession> implements UpdateValidatable {
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

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 metconId;
  DateTime datetime;
  int? time;
  int? rounds;
  int? reps;
  bool rx;
  String? comments;
  bool deleted;

  factory MetconSession.fromJson(Map<String, dynamic> json) => _$MetconSessionFromJson(json);
  Map<String, dynamic> toJson() => _$MetconSessionToJson(this);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return MetconSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      metconId: Value(metconId),
      datetime: Value(datetime),
      time: Value(time),
      rounds: Value(rounds),
      reps: Value(reps),
      rx: Value(rx),
      comments: Value(comments),
      deleted: Value(deleted),
    ).toColumns(false);
  }

  @override
  bool validateOnUpdate() {
    return deleted != true
        && (time == null || time! > 0)
        && (rounds == null || rounds! > 0)
        && (reps == null || reps! > 0);
  }
}