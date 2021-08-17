
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';

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
  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 metconId;
  @DateTimeConverter() DateTime datetime;
  int? time;
  int? rounds;
  int? reps;
  bool rx;
  String? comments;
  @override
  bool deleted;

  factory MetconSession.fromJson(Map<String, dynamic> json) => _$MetconSessionFromJson(json);
  Map<String, dynamic> toJson() => _$MetconSessionToJson(this);

  @override
  bool isValid() {
    return deleted != true
        && (time == null || time! > 0)
        && (rounds == null || rounds! > 0)
        && (reps == null || reps! > 0);
  }
}