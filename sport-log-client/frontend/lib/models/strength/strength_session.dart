
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/update_validatable.dart';

part 'strength_session.g.dart';

@JsonSerializable()
class StrengthSession extends Insertable implements UpdateValidatable {
  StrengthSession({
    required this.id,
    required this.userId,
    required this.datetime,
    required this.movementId,
    required this.movementUnit,
    required this.interval,
    required this.comments,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  DateTime datetime;
  @IdConverter() Int64 movementId;
  MovementUnit movementUnit;
  int? interval;
  String? comments;
  bool deleted;

  factory StrengthSession.fromJson(Map<String, dynamic> json) => _$StrengthSessionFromJson(json);
  Map<String, dynamic> toJson() => _$StrengthSessionToJson(this);

  @override
  bool validateOnUpdate() {
    return !deleted
        && (interval == null || interval! > 0);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return StrengthSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      datetime: Value(datetime),
      movementId: Value(movementId),
      movementUnit: Value(movementUnit),
      interval: Value(interval),
      comments: Value(comments),
      deleted: Value(deleted),
    ).toColumns(false);
  }
}