
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'strength_session.g.dart';

@JsonSerializable()
class StrengthSession {
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

  int id;
  int userId;
  DateTime datetime;
  int movementId;
  MovementUnit movementUnit;
  int? interval;
  String? comments;
  bool deleted;

  factory StrengthSession.fromJson(Map<String, dynamic> json) => _$StrengthSessionFromJson(json);
  Map<String, dynamic> toJson() => _$StrengthSessionToJson(this);
}