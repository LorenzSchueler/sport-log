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

part 'route.g.dart';

@JsonSerializable()
class Route extends AtomicEntity with Comparable<Route> {
  Route({
    required this.id,
    required this.userId,
    required this.name,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.track,
    required this.markedPositions,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
  String name;
  int distance;
  int? ascent;
  int? descent;
  List<Position>? track;
  List<Position>? markedPositions;
  @override
  bool deleted;

  Route.defaultValue()
      : id = randomId(),
        userId = Settings.userId!,
        name = "",
        distance = 0,
        ascent = null,
        descent = null,
        deleted = false;

  void setDistance() {
    distance =
        track == null || track!.isEmpty ? 0 : track!.last.distance.round();
  }

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

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  @override
  Route clone() => Route(
        id: id.clone(),
        userId: userId.clone(),
        name: name,
        distance: distance,
        ascent: ascent,
        descent: descent,
        track: track?.map((p) => p.clone()).toList(),
        markedPositions: markedPositions?.map((p) => p.clone()).toList(),
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitazion() {
    return validate(!deleted, 'Route: deleted == true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Route: name.length is < 2 or > 80',
        ) &&
        validate(distance > 0, 'Route: distance <= 0') &&
        validate(ascent == null || ascent! >= 0, 'Route: ascent < 0') &&
        validate(descent == null || descent! >= 0, 'Route: descent < 0');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        validate(
          track == null || track!.isNotEmpty,
          'Route: track is empty but not null',
        ) &&
        validate(
          markedPositions == null || markedPositions!.isNotEmpty,
          'Route: markedPositions is empty but not null',
        );
  }

  @override
  void sanitize() {
    if (track != null && track!.isEmpty) {
      track = null;
    }
    if (markedPositions != null && markedPositions!.isEmpty) {
      markedPositions = null;
    }
  }

  @override
  int compareTo(Route other) {
    return name.compareTo(other.name);
  }
}

class DbRouteSerializer extends DbSerializer<Route> {
  @override
  Route fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Route(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
      name: r[prefix + Columns.name]! as String,
      distance: r[prefix + Columns.distance]! as int,
      ascent: r[prefix + Columns.ascent] as int?,
      descent: r[prefix + Columns.descent] as int?,
      track: DbPositionListConverter.mapToDart(
        r[prefix + Columns.track] as Uint8List?,
      ),
      markedPositions: DbPositionListConverter.mapToDart(
        r[prefix + Columns.markedPositions] as Uint8List?,
      ),
      deleted: r[prefix + Columns.deleted] == 1,
    );
  }

  @override
  DbRecord toDbRecord(Route o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId.toInt(),
      Columns.name: o.name,
      Columns.distance: o.distance,
      Columns.ascent: o.ascent,
      Columns.descent: o.descent,
      Columns.track: DbPositionListConverter.mapToSql(o.track),
      Columns.markedPositions:
          DbPositionListConverter.mapToSql(o.markedPositions),
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
