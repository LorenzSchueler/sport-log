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
class Route extends AtomicEntity {
  Route({
    required this.id,
    required this.name,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.track,
    required this.markedPositions,
    required this.deleted,
  });

  Route.defaultValue()
    : id = randomId(),
      name = "",
      distance = 0,
      ascent = null,
      descent = null,
      deleted = false;

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @JsonKey(includeToJson: true, name: "user_id")
  @IdConverter()
  Int64 get _userId => Settings.instance.userId!;
  String name;
  int? distance;
  int? ascent;
  int? descent;
  List<Position>? track;
  List<Position>? markedPositions;
  @override
  bool deleted;

  void setDistance() => distance = track?.lastOrNull?.distance.round() ?? 0;

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

  @override
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  @override
  Route clone() => Route(
    id: id.clone(),
    name: name,
    distance: distance,
    ascent: ascent,
    descent: descent,
    track: track?.clone(),
    markedPositions: markedPositions?.clone(),
    deleted: deleted,
  );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'Route: deleted == true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Route: name.length is < 2 or > 80',
        ) &&
        validate(distance == null || distance! >= 0, 'Route: distance < 0') &&
        validate(ascent == null || ascent! >= 0, 'Route: ascent < 0') &&
        validate(descent == null || descent! >= 0, 'Route: descent < 0');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(distance == null || distance! > 0, 'Route: distance <= 0') &&
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
    if (distance != null && distance! <= 0) {
      distance = null;
    }
    if (track != null && track!.isEmpty) {
      track = null;
    }
    if (markedPositions != null && markedPositions!.isEmpty) {
      markedPositions = null;
    }
  }
}

class DbRouteSerializer extends DbSerializer<Route> {
  @override
  Route fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Route(
      id: Int64(r[prefix + Columns.id]! as int),
      name: r[prefix + Columns.name]! as String,
      distance: r[prefix + Columns.distance] as int?,
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
      Columns.name: o.name,
      Columns.distance: o.distance,
      Columns.ascent: o.ascent,
      Columns.descent: o.descent,
      Columns.track: DbPositionListConverter.mapToSql(o.track),
      Columns.markedPositions: DbPositionListConverter.mapToSql(
        o.markedPositions,
      ),
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
