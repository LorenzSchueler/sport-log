import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/clone_extensions.dart';
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
  @OptionalDurationListConverter()
  List<Duration>? cadence;
  int? avgHeartRate;
  @OptionalDurationListConverter()
  List<Duration>? heartRate;
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
  CardioSession clone() => CardioSession(
        id: id.clone(),
        userId: userId.clone(),
        movementId: movementId.clone(),
        cardioType: cardioType,
        datetime: datetime.clone(),
        distance: distance,
        ascent: ascent,
        descent: descent,
        time: time?.clone(),
        calories: calories,
        track: track?.map((p) => p.clone()).toList(),
        avgCadence: avgCadence,
        cadence: cadence == null ? null : [...cadence!],
        avgHeartRate: avgHeartRate,
        heartRate: heartRate == null ? null : [...heartRate!],
        routeId: routeId?.clone(),
        comments: comments,
        deleted: deleted,
      );

  @override
  bool isValidIgnoreEmptyNotNull() {
    return validate(!deleted, 'CardioSession: deleted is true') &&
        validate(
          ascent == null || ascent! >= 0,
          'CardioSession: ascent < 0',
        ) &&
        validate(
          descent == null || descent! >= 0,
          'CardioSession: descent < 0',
        ) &&
        validate(
          calories == null || calories! >= 0,
          'CardioSession: calories < 0',
        ) &&
        validate(
          distance == null || distance! > 0,
          'CardioSession: distance <= 0',
        ) &&
        validate(
          avgCadence == null || avgCadence! >= 0,
          'CardioSession: avgCadence < 0',
        ) &&
        validate(
          avgHeartRate == null || avgHeartRate! >= 0,
          'CardioSession: avgHeartRate < 0',
        ) &&
        validate(
          time == null || time! > const Duration(),
          'CardioSession: time <= 0',
        ) &&
        validate(
          track == null || track!.isEmpty || distance != null,
          'CardioSession: distance == null when track is set',
        ) &&
        validate(
          cadence == null || cadence!.isEmpty || avgCadence != null,
          'CardioSession: avgCadence == null when cadence is set',
        ) &&
        validate(
          heartRate == null || heartRate!.isEmpty || avgHeartRate != null,
          'CardioSession: avgHeartRate == null when heartRate is set',
        );
  }

  @override
  bool isValid() {
    return isValidIgnoreEmptyNotNull() &&
        validate(
          avgCadence == null || avgCadence! > 0,
          'CardioSession: avgCadence <= 0',
        ) &&
        validate(
          avgHeartRate == null || avgHeartRate! > 0,
          'CardioSession: avgHeartRate <= 0',
        ) &&
        validate(
          track == null || track!.isNotEmpty,
          'CardioSession: track is empty but not null',
        ) &&
        validate(
          cadence == null || cadence!.isNotEmpty,
          'CardioSession: cadence is empty but not null',
        ) &&
        validate(
          heartRate == null || heartRate!.isNotEmpty,
          'CardioSession: heartRate is empty but not null',
        ) &&
        validate(
          comments == null || comments!.isNotEmpty,
          'CardioSession: comments is empty but not null',
        );
  }

  @override
  void setEmptyToNull() {
    if (track != null && track!.isEmpty) {
      track = null;
    }
    if (cadence != null && cadence!.isEmpty) {
      cadence = null;
    }
    if (heartRate != null && heartRate!.isEmpty) {
      heartRate = null;
    }
    if (comments != null && comments!.isEmpty) {
      comments = null;
    }
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
          : Duration(milliseconds: r[prefix + Columns.time]! as int),
      calories: r[prefix + Columns.calories] as int?,
      track: const DbPositionListConverter()
          .mapToDart(r[prefix + Columns.track] as Uint8List?),
      avgCadence: r[prefix + Columns.avgCadence] as int?,
      cadence: const DbDurationListConverter()
          .mapToDart(r[prefix + Columns.cadence] as Uint8List?),
      avgHeartRate: r[prefix + Columns.avgHeartRate] as int?,
      heartRate: const DbDurationListConverter()
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
      Columns.time: o.time?.inMilliseconds,
      Columns.calories: o.calories,
      Columns.track: const DbPositionListConverter().mapToSql(o.track),
      Columns.avgCadence: o.avgCadence,
      Columns.cadence: const DbDurationListConverter().mapToSql(o.cadence),
      Columns.avgHeartRate: o.avgHeartRate,
      Columns.heartRate: const DbDurationListConverter().mapToSql(o.heartRate),
      Columns.routeId: o.routeId?.toInt(),
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
