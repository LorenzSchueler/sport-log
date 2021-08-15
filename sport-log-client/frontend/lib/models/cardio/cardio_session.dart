
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/helpers/update_validatable.dart';

part 'cardio_session.g.dart';

enum CardioType {
  @JsonValue("Training") training,
  @JsonValue("ActiveRecovery") activeRecovery,
  @JsonValue("Freetime") freetime
}

@JsonSerializable()
class CardioSession extends Insertable implements UpdateValidatable {
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
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 movementId;
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
  @OptionalIdConverter() Int64? routeId;
  String? comments;
  bool deleted;

  factory CardioSession.fromJson(Map<String, dynamic> json) => _$CardioSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CardioSessionToJson(this);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return CardioSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      movementId: Value(movementId),
      cardioType: Value(cardioType),
      datetime: Value(datetime),
      distance: Value(distance),
      ascent: Value(ascent),
      descent: Value(descent),
      time: Value(time),
      calories: Value(calories),
      track: Value(track),
      avgCycles: Value(avgCycles),
      cycles: Value(cycles),
      avgHeartRate: Value(avgHeartRate),
      heartRate: Value(heartRate),
      routeId: Value(routeId),
      comments: Value(comments),
      deleted: Value(deleted),
    ).toColumns(false);
  }

  @override
  bool validateOnUpdate() {
    return !deleted
        && [ascent, descent]
          .every((val) => val == null || val >= 0)
        && [distance, time, calories, avgCycles, avgHeartRate]
          .every((val) => val == null || val > 0)
        && (track == null || distance != null)
        && (cycles == null || avgCycles != null)
        && (heartRate == null || avgHeartRate != null);
  }
}