import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

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
class CardioSession extends AtomicEntity {
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
  @OptionalDurationConverter()
  Duration? time;
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

  CardioSession.defaultValue(this.movementId)
      : id = randomId(),
        userId = Settings.userId!,
        cardioType = CardioType.training,
        datetime = DateTime.now(),
        deleted = false;

  void setAvgCadenceFromCadenceAndTime() {
    avgCadence = time!.inSeconds == 0
        ? 0
        : (cadence!.length / time!.inSeconds * 60).round();
  }

  factory CardioSession.fromJson(Map<String, dynamic> json) =>
      _$CardioSessionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CardioSessionToJson(this);

  @override
  CardioSession clone() => CardioSession.fromJson(toJson());

  @override
  bool isValid() {
    return validate(!deleted, 'CardioSession: deleted is true') &&
        validate(
          [ascent, descent].every((val) => val == null || val >= 0),
          'CardioSession: ascent or descent < 0',
        ) &&
        validate(
          [distance, calories, avgCadence, avgHeartRate]
              .every((val) => val == null || val > 0),
          'CardioSession: distance, time, calories, avgCadence or avgHeartRate <= 0',
        ) &&
        validate(
          time == null || time!.inSeconds > 0,
          'CardioSession: time <= 0',
        ) &&
        validate(
          track == null || distance != null,
          'CardioSession: distance == null when track is set',
        ) &&
        validate(
          cadence == null || avgCadence != null,
          'CardioSession: avgCadence == null when cadence is set',
        ) &&
        validate(
          heartRate == null || avgHeartRate != null,
          'CardioSession: avgHeartRate == null when heartRate is set',
        );
  }
}

class DbCardioSessionSerializer extends DbSerializer<CardioSession> {
  @override
  CardioSession fromDbRecord(DbRecord r, {String prefix = ''}) {
    return CardioSession(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
      movementId: Int64(r[prefix + Columns.movementId]! as int),
      cardioType: CardioType.values[r[prefix + Columns.cardioType]! as int],
      datetime: DateTime.parse(r[prefix + Columns.datetime]! as String),
      distance: r[prefix + Columns.distance] as int?,
      ascent: r[prefix + Columns.ascent] as int?,
      descent: r[prefix + Columns.descent] as int?,
      time: r[prefix + Columns.time] == null
          ? null
          : Duration(seconds: r[prefix + Columns.time]! as int),
      calories: r[prefix + Columns.calories] as int?,
      track: const DbPositionListConverter()
          .mapToDart(r[prefix + Columns.track] as Uint8List?),
      avgCadence: r[prefix + Columns.avgCadence] as int?,
      cadence: const DbDoubleListConverter()
          .mapToDart(r[prefix + Columns.cadence] as Uint8List?),
      avgHeartRate: r[prefix + Columns.avgHeartRate] as int?,
      heartRate: const DbDoubleListConverter()
          .mapToDart(r[prefix + Columns.heartRate] as Uint8List?),
      routeId: r[prefix + Columns.routeId] == null
          ? null
          : Int64(r[prefix + Columns.routeId]! as int),
      comments: r[prefix + Columns.comments] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(CardioSession o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId.toInt(),
      Columns.movementId: o.movementId.toInt(),
      Columns.cardioType: o.cardioType.index,
      Columns.datetime: o.datetime.toString(),
      Columns.distance: o.distance,
      Columns.ascent: o.ascent,
      Columns.descent: o.descent,
      Columns.time: o.time?.inSeconds,
      Columns.calories: o.calories,
      Columns.track: const DbPositionListConverter().mapToSql(o.track),
      Columns.avgCadence: o.avgCadence,
      Columns.cadence: const DbDoubleListConverter().mapToSql(o.cadence),
      Columns.avgHeartRate: o.avgHeartRate,
      Columns.heartRate: const DbDoubleListConverter().mapToSql(o.heartRate),
      Columns.routeId: o.routeId?.toInt(),
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
