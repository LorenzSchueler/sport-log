
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/cardio/position.dart';

part 'cardio_session.g.dart';

enum CardioType {
  @JsonValue("Training") training,
  @JsonValue("ActiveRecovery") activeRecovery,
  @JsonValue("Freetime") freetime
}

@JsonSerializable()
class CardioSession {
  CardioSession({
    required this.id,
    required this.userId,
    required this.movementId,
    required this.cardioType,
    required this.datetime,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.time,
    required this.calories,
    required this.track,
    required this.avgCycles,
    required this.cycles,
    required this.avgHeartRate,
    required this.heartRate,
    required this.routeId,
    required this.comments,
  });

  int id;
  int userId;
  int movementId;
  CardioType cardioType;
  DateTime datetime;
  int? distance;
  int? ascent;
  int? descent;
  int? time;
  int? calories;
  List<Position>? track;
  int? avgCycles;
  List<double>? cycles;
  int? avgHeartRate;
  List<double>? heartRate;
  int? routeId;
  String? comments;

  factory CardioSession.fromJson(Map<String, dynamic> json) => _$CardioSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CardioSessionToJson(this);
}