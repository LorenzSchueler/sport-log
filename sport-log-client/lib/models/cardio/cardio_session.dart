import 'dart:typed_data';

import 'package:collection/collection.dart';
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
  freetime;

  @override
  String toString() {
    switch (this) {
      case CardioType.training:
        return "Training";
      case CardioType.activeRecovery:
        return "Active Recovery";
      case CardioType.freetime:
        return "Freetime";
    }
  }
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

  CardioSession.defaultValue(this.movementId)
      : id = randomId(),
        userId = Settings.instance.userId!,
        cardioType = CardioType.training,
        datetime = DateTime.now(),
        deleted = false;

  factory CardioSession.fromJson(Map<String, dynamic> json) =>
      _$CardioSessionFromJson(json);

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

  static const _currentDurationOffset = Duration(minutes: 1);

  /// km/h
  double? get speed {
    return time == null || time!.inMilliseconds == 0 || distance == null
        ? null
        : (distance! / 1000) / (time!.inMilliseconds / (1000 * 60 * 60));
  }

  /// km/h
  double? currentSpeed(Duration currentDuration) {
    if (time == null || time!.inMilliseconds == 0 || track == null) {
      return null;
    } else {
      final lastPositions = track!.where(
        (position) => position.time >= currentDuration - _currentDurationOffset,
      );
      final distance = lastPositions.isEmpty
          ? 0.0
          : lastPositions.last.distance - lastPositions.first.distance;
      final time = lastPositions.isEmpty
          ? Duration.zero
          : lastPositions.last.time - lastPositions.first.time;
      return time.inMilliseconds == 0
          ? null
          : (distance / 1000) / (time.inMilliseconds / (1000 * 60 * 60));
    }
  }

  /// min/km
  Duration? get tempo {
    final speed = this.speed;
    return speed == null || speed == 0
        ? null
        : Duration(milliseconds: (60 * 60 * 1000 / speed).round());
  }

  /// min/km
  Duration? currentTempo(Duration currentDuration) {
    final speed = currentSpeed(currentDuration);
    return speed == null || speed == 0
        ? null
        : Duration(milliseconds: (60 * 60 * 1000 / speed).round());
  }

  /// rpm
  int? currentCadence(Duration currentDuration) {
    if (time == null || time!.inMilliseconds == 0 || cadence == null) {
      return null;
    } else {
      final lastCadence =
          cadence!.where((d) => d >= currentDuration - _currentDurationOffset);
      final time = lastCadence.isEmpty
          ? Duration.zero
          : lastCadence.last - lastCadence.first;
      return time.inMilliseconds == 0 || lastCadence.isEmpty
          ? null
          : (lastCadence.length / (time.inMilliseconds / (1000 * 60))).round();
    }
  }

  /// bpm
  int? currentHeartRate(Duration currentDuration) {
    if (time == null || time!.inMilliseconds == 0 || heartRate == null) {
      return null;
    } else {
      final lastHeartRate = heartRate!
          .where((d) => d >= currentDuration - _currentDurationOffset);
      final time = lastHeartRate.isEmpty
          ? Duration.zero
          : lastHeartRate.last - lastHeartRate.first;
      return time.inMilliseconds == 0 || lastHeartRate.isEmpty
          ? null
          : (lastHeartRate.length / (time.inMilliseconds / (1000 * 60)))
              .round();
    }
  }

  void setEmptyListsToNull() {
    if (track != null && track!.isEmpty) {
      track = null;
    }
    if (cadence != null && cadence!.isEmpty) {
      cadence = null;
    }
    if (heartRate != null && heartRate!.isEmpty) {
      heartRate = null;
    }
  }

  void setDistance() => distance = track?.lastOrNull?.distance.round();

  void setAscentDescent() {
    if (track == null || track!.isEmpty) {
      this.ascent = null;
      this.descent = null;
      return;
    }
    double ascent = 0;
    double descent = 0;
    for (int i = 0; i < track!.length - 1; i++) {
      double elevationDifference =
          track![i + 1].elevation - track![i].elevation;
      if (elevationDifference > 0) {
        ascent += elevationDifference;
      } else {
        descent -= elevationDifference;
      }
    }
    this.ascent = ascent.round();
    this.descent = descent.round();
  }

  void setAvgCadence() {
    avgCadence = time == null || time!.inMilliseconds == 0 || cadence == null
        ? null
        : (cadence!.length / (time!.inMilliseconds / (1000 * 60))).round();
  }

  void setAvgHeartRate() {
    avgHeartRate = time == null ||
            time!.inMilliseconds == 0 ||
            heartRate == null
        ? null
        : (heartRate!.length / (time!.inMilliseconds / (1000 * 60))).round();
  }

  void cut(Duration start, Duration end) {
    assert(start < end);
    time = end - start;
    if (track != null && track!.isNotEmpty) {
      final newTrack =
          track!.where((pos) => pos.time >= start && pos.time <= end);
      if (newTrack.isNotEmpty) {
        final distanceOffset = newTrack.first.distance;
        final timeOffset = newTrack.first.time;
        track = newTrack
            .map(
              (pos) => pos
                ..distance -= distanceOffset
                ..time -= timeOffset,
            )
            .toList();
      } else {
        track = null;
      }
      setDistance();
      setAscentDescent();
    }
    if (cadence != null && cadence!.isNotEmpty) {
      final newCadence = cadence!.where((time) => time >= start && time <= end);
      if (newCadence.isNotEmpty) {
        final timeOffset = newCadence.first;
        cadence = newCadence.map((time) => time - timeOffset).toList();
      } else {
        cadence = null;
      }
      setAvgCadence();
    }
    if (heartRate != null && heartRate!.isNotEmpty) {
      final newHeartRate =
          heartRate!.where((time) => time >= start && time <= end);
      if (newHeartRate.isNotEmpty) {
        final timeOffset = newHeartRate.first;
        heartRate = newHeartRate.map((time) => time - timeOffset).toList();
      } else {
        heartRate = null;
      }
      setAvgHeartRate();
    }
  }

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
  bool isValidBeforeSanitation() {
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
          avgCadence == null || avgCadence! >= 0,
          'CardioSession: avgCadence < 0',
        ) &&
        validate(
          avgHeartRate == null || avgHeartRate! >= 0,
          'CardioSession: avgHeartRate < 0',
        ) &&
        validate(
          time == null || time! > Duration.zero,
          'CardioSession: time <= 0',
        ) &&
        validate(
          track == null || track!.length <= 1 || distance != null,
          'CardioSession: distance == null when track is set',
        ) &&
        validate(
          cadence == null || cadence!.length <= 1 || avgCadence != null,
          'CardioSession: avgCadence == null when cadence is set',
        ) &&
        validate(
          heartRate == null || heartRate!.length <= 1 || avgHeartRate != null,
          'CardioSession: avgHeartRate == null when heartRate is set',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          distance == null || distance! > 0,
          'CardioSession: distance <= 0',
        ) &&
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
  void sanitize() {
    if (time != null && time! <= Duration.zero) {
      time = null;
    }
    if (distance != null && distance! <= 0) {
      distance = null;
      track = null;
    }
    if (track != null && track!.isEmpty) {
      track = null;
    }
    if (avgCadence != null && avgCadence! <= 0) {
      avgCadence = null;
      cadence = null;
    }
    if (cadence != null && cadence!.isEmpty) {
      cadence = null;
    }
    if (avgHeartRate != null && avgHeartRate! <= 0) {
      avgHeartRate = null;
      heartRate = null;
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
      track: DbPositionListConverter.mapToDart(
        r[prefix + Columns.track] as Uint8List?,
      ),
      avgCadence: r[prefix + Columns.avgCadence] as int?,
      cadence: DbDurationListConverter.mapToDart(
        r[prefix + Columns.cadence] as Uint8List?,
      ),
      avgHeartRate: r[prefix + Columns.avgHeartRate] as int?,
      heartRate: DbDurationListConverter.mapToDart(
        r[prefix + Columns.heartRate] as Uint8List?,
      ),
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
      Columns.track: DbPositionListConverter.mapToSql(o.track),
      Columns.avgCadence: o.avgCadence,
      Columns.cadence: DbDurationListConverter.mapToSql(o.cadence),
      Columns.avgHeartRate: o.avgHeartRate,
      Columns.heartRate: DbDurationListConverter.mapToSql(o.heartRate),
      Columns.routeId: o.routeId?.toInt(),
      Columns.comments: o.comments,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
