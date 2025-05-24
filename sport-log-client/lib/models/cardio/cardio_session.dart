import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/search.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

part 'cardio_session.g.dart';

enum CardioType {
  @JsonValue("Training")
  training("Training"),
  @JsonValue("ActiveRecovery")
  activeRecovery("Active Recovery"),
  @JsonValue("Freetime")
  freetime("Freetime");

  const CardioType(this.name);

  final String name;
}

@JsonSerializable()
class CardioSession extends AtomicEntity {
  CardioSession({
    required this.id,
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
      cardioType = CardioType.training,
      datetime = DateTime.now(),
      deleted = false;

  factory CardioSession.fromJson(Map<String, dynamic> json) =>
      _$CardioSessionFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @JsonKey(includeToJson: true, name: "user_id")
  @IdConverter()
  Int64 get _userId => Settings.instance.userId!;
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

  /// km/h
  double? get speed {
    return time == null || time!.isZero || distance == null
        ? null
        : (distance! / 1000) / time!.inHourFractions;
  }

  /// km/h
  double? currentSpeed(Duration start, Duration end) {
    if (track != null) {
      final startIndex = binarySearchSmallestGE(
        track!,
        (Position p) => p.time,
        start,
      );
      final endIndex = binarySearchLargestLE(
        track!,
        (Position p) => p.time,
        end,
      );
      if (startIndex != null && endIndex != null) {
        final startPos = track![startIndex];
        final endPos = track![endIndex];
        final km = (endPos.distance - startPos.distance) / 1000;
        final hours = (endPos.time - startPos.time).inHourFractions;
        if (hours > 0) {
          return km / hours;
        }
      }
    }
    return null;
  }

  /// min/km
  Duration? get tempo {
    final speed = this.speed;
    return speed == null || speed == 0
        ? null
        : Duration(milliseconds: (60 * 60 * 1000 / speed).round());
  }

  /// min/km
  Duration? currentTempo(Duration start, Duration end) {
    final speed = currentSpeed(start, end);
    return speed == null || speed == 0
        ? null
        : Duration(milliseconds: (60 * 60 * 1000 / speed).round());
  }

  /// rpm
  int? currentCadence(Duration start, Duration end) {
    if (cadence != null) {
      final startIndex = binarySearchSmallestGE(
        cadence!,
        (Duration d) => d,
        start,
      );
      final endIndex = binarySearchLargestLE(cadence!, (Duration d) => d, end);
      if (startIndex != null && endIndex != null) {
        final startCadence = cadence![startIndex];
        final endCadence = cadence![endIndex];
        final minutes = (endCadence - startCadence).inMinuteFractions;
        if (minutes > 0) {
          return ((endIndex - startIndex) / minutes).round();
        }
      }
    }
    return null;
  }

  /// bpm
  int? currentHeartRate(Duration start, Duration end) {
    if (heartRate != null) {
      final startIndex = binarySearchSmallestGE(
        heartRate!,
        (Duration d) => d,
        start,
      );
      final endIndex = binarySearchLargestLE(
        heartRate!,
        (Duration d) => d,
        end,
      );
      if (startIndex != null && endIndex != null) {
        final startHR = heartRate![startIndex];
        final endHR = heartRate![endIndex];
        final minutes = (endHR - startHR).inMinuteFractions;
        if (minutes > 0) {
          return ((endIndex - startIndex) / minutes).round();
        }
      }
    }
    return null;
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
    var ascent = 0.0;
    var descent = 0.0;
    for (var i = 0; i < track!.length - 1; i++) {
      final elevationDifference = track![i + 1].elevation - track![i].elevation;
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
    avgCadence = time == null || time!.isZero || cadence == null
        ? null
        : (cadence!.length / time!.inMinuteFractions).round();
  }

  void setAvgHeartRate() {
    avgHeartRate = time == null || time!.isZero || heartRate == null
        ? null
        : (heartRate!.length / (time!.inMinuteFractions)).round();
  }

  CardioSession? cut(Duration start, Duration end) {
    if (end < start) {
      if (end < time!) {
        final endSession = clone()
          ..cut(start, time!)
          ..datetime = datetime.add(end);
        cut(Duration.zero, end);
        return combineWith(endSession)
          ?..sanitize()
          ..id = id;
      }
      return null;
    }
    time = end - start;
    if (track != null && track!.isNotEmpty) {
      final newTrack = track!.where(
        (pos) => pos.time >= start && pos.time <= end,
      );
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
      final newHeartRate = heartRate!.where(
        (time) => time >= start && time <= end,
      );
      if (newHeartRate.isNotEmpty) {
        final timeOffset = newHeartRate.first;
        heartRate = newHeartRate.map((time) => time - timeOffset).toList();
      } else {
        heartRate = null;
      }
      setAvgHeartRate();
    }
    return this..sanitize();
  }

  // ignore: long-method
  CardioSession? combineWith(CardioSession other) {
    final CardioSession session1, session2;
    if (datetime.compareTo(other.datetime) < 0) {
      session1 = this;
      session2 = other;
    } else {
      session1 = other;
      session2 = this;
    }

    final time1 = session1.time;
    final track1 = session1.track;
    final time2 = session2.time;
    final track2 = session2.track;
    if (time1 == null ||
        track1 == null ||
        track1.isEmpty ||
        time2 == null ||
        track2 == null ||
        track2.isEmpty) {
      return null;
    }

    final betweenTime = session2.datetime.difference(
      session1.datetime.add(session1.time!),
    );
    if (betweenTime.isNegative) {
      return null;
    }

    final time = time1 + betweenTime + time2;
    final shiftTime = time1 + betweenTime;
    final shiftDistance =
        track1.last.distance + track1.last.distanceTo(track2.first);
    final track =
        track1 +
        track2.map((position) {
          position
            ..time += shiftTime
            ..distance += shiftDistance;
          return position;
        }).toList();
    final cadence =
        (session1.cadence ?? []) +
        (session2.cadence?.map((time) => time + shiftTime).toList() ?? []);
    final heartRate =
        (session1.heartRate ?? []) +
        (session2.heartRate?.map((time) => time + shiftTime).toList() ?? []);
    return CardioSession(
        id: randomId(),
        movementId: session1.movementId,
        cardioType: session1.cardioType,
        datetime: session1.datetime,
        distance: null, // set later
        ascent: null, // set later
        descent: null, // set later
        time: time,
        calories: null,
        track: track,
        avgCadence: null, // set later
        cadence: cadence,
        avgHeartRate: null, // set later
        heartRate: heartRate,
        routeId: session1.routeId,
        comments: session1.comments,
        deleted: false,
      )
      ..setDistance()
      ..setAscentDescent()
      ..setAvgCadence()
      ..setAvgHeartRate();
  }

  bool similarTo(CardioSession other) =>
      movementId == other.movementId &&
      track != null &&
      other.track != null &&
      track!.similarTo(other.track!);

  @override
  Map<String, dynamic> toJson() => _$CardioSessionToJson(this);

  @override
  CardioSession clone() => CardioSession(
    id: id.clone(),
    movementId: movementId.clone(),
    cardioType: cardioType,
    datetime: datetime.clone(),
    distance: distance,
    ascent: ascent,
    descent: descent,
    time: time?.clone(),
    calories: calories,
    track: track?.clone(),
    avgCadence: avgCadence,
    cadence: cadence?.clone(),
    avgHeartRate: avgHeartRate,
    heartRate: heartRate?.clone(),
    routeId: routeId?.clone(),
    comments: comments,
    deleted: deleted,
  );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'CardioSession: deleted is true') &&
        validate(
          distance == null || distance! >= 0,
          'CardioSession: distance < 0',
        ) &&
        validate(ascent == null || ascent! >= 0, 'CardioSession: ascent < 0') &&
        validate(
          descent == null || descent! >= 0,
          'CardioSession: descent < 0',
        ) &&
        validate(
          time == null || time! >= Duration.zero,
          'CardioSession: time < 0',
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
          time == null || time! > Duration.zero,
          'CardioSession: time <= 0',
        ) &&
        validate(
          track == null || track!.isNotEmpty,
          'CardioSession: track is empty but not null',
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
          cadence == null || cadence!.isNotEmpty,
          'CardioSession: cadence is empty but not null',
        ) &&
        validate(
          heartRate == null || heartRate!.isNotEmpty,
          'CardioSession: heartRate is empty but not null',
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
    }
    if (track != null && track!.isEmpty || distance == null) {
      track = null;
    }
    if (avgCadence != null && avgCadence! <= 0) {
      avgCadence = null;
    }
    if (cadence != null && cadence!.isEmpty || avgCadence == null) {
      cadence = null;
    }
    if (avgHeartRate != null && avgHeartRate! <= 0) {
      avgHeartRate = null;
    }
    if (heartRate != null && heartRate!.isEmpty || avgHeartRate == null) {
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
