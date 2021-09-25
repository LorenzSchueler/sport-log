import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';

part 'cardio_session.g.dart';

enum CardioType {
  @JsonValue("Training")
  training,
  @JsonValue("ActiveRecovery")
  activeRecovery,
  @JsonValue("Freetime")
  freetime
}

@JsonSerializable()
class CardioSession implements DbObject {
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
    required this.avgCadence,
    required this.cadence,
    required this.avgHeartRate,
    required this.heartRate,
    required this.routeId,
    required this.comments,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @OptionalIdConverter()
  Int64? cardioBlueprintId;
  @IdConverter()
  Int64 userId;
  @IdConverter()
  Int64 movementId;
  CardioType cardioType;
  @DateTimeConverter()
  DateTime datetime;
  int? distance;
  int? ascent;
  int? descent;
  int? time;
  int? calories;
  List<Position>? track;
  int? avgCadence;
  List<double>? cadence;
  int? avgHeartRate;
  List<double>? heartRate;
  @OptionalIdConverter()
  Int64? routeId;
  String? comments;
  @override
  bool deleted;

  factory CardioSession.fromJson(Map<String, dynamic> json) =>
      _$CardioSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CardioSessionToJson(this);

  @override
  bool isValid() {
    return validate(!deleted, 'CardioSession: deleted is true') &&
        validate([ascent, descent].every((val) => val == null || val >= 0),
            'CardioSession: ascent or descent < 0') &&
        validate(
            [distance, time, calories, avgCadence, avgHeartRate]
                .every((val) => val == null || val > 0),
            'CardioSession: distance, time, calories, avgCadence or avgHeartRate <= 0') &&
        validate((track == null || distance != null),
            'CardioSession: distance == null when track is set') &&
        validate((cadence == null || avgCadence != null),
            'CardioSession: avgCadence == null when cadence is set') &&
        validate((heartRate == null || avgHeartRate != null),
            'CardioSession: avgHeartRate == null when heartRate is set');
  }
}

class DbCardioSessionSerializer implements DbSerializer<CardioSession> {
  @override
  CardioSession fromDbRecord(DbRecord r, {String prefix = ''}) {
    return CardioSession(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      movementId: Int64(r[Keys.movementId]! as int),
      cardioType: CardioType.values[r[Keys.cardioType]! as int],
      datetime: DateTime.parse(r[Keys.datetime]! as String),
      distance: r[Keys.distance] as int?,
      ascent: r[Keys.ascent] as int?,
      descent: r[Keys.descent] as int?,
      time: r[Keys.time] as int?,
      calories: r[Keys.calories] as int?,
      track: const DbPositionListConverter()
          .mapToDart(r[Keys.track] as Uint8List?),
      avgCadence: r[Keys.avgCadence] as int?,
      cadence: const DbDoubleListConverter()
          .mapToDart(r[Keys.cadence] as Uint8List?),
      avgHeartRate: r[Keys.avgHeartRate] as int?,
      heartRate: const DbDoubleListConverter()
          .mapToDart(r[Keys.heartRate] as Uint8List?),
      routeId: r[Keys.routeId] == null ? null : Int64(r[Keys.routeId]! as int),
      comments: r[Keys.comments] as String?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(CardioSession o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.movementId: o.movementId.toInt(),
      Keys.cardioType: o.cardioType.index,
      Keys.datetime: o.datetime.toString(),
      Keys.distance: o.distance,
      Keys.ascent: o.ascent,
      Keys.descent: o.descent,
      Keys.time: o.time,
      Keys.calories: o.calories,
      Keys.track: const DbPositionListConverter().mapToSql(o.track),
      Keys.avgCadence: o.avgCadence,
      Keys.cadence: const DbDoubleListConverter().mapToSql(o.cadence),
      Keys.avgHeartRate: o.avgHeartRate,
      Keys.heartRate: const DbDoubleListConverter().mapToSql(o.heartRate),
      Keys.routeId: o.routeId?.toInt(),
      Keys.comments: o.comments,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
