
import 'package:json_annotation/json_annotation.dart';

part 'metcon_session.g.dart';

@JsonSerializable()
class MetconSession {
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
  });

  int id;
  int userId;
  int metconId;
  DateTime datetime;
  int? time;
  int? rounds;
  int? reps;
  bool rx;
  String? comments;

  factory MetconSession.fromJson(Map<String, dynamic> json) => _$MetconSessionFromJson(json);
  Map<String, dynamic> toJson() => _$MetconSessionToJson(this);
}