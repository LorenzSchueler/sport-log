
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';

part 'route.g.dart';

@JsonSerializable()
class Route implements DbObject {
  Route({
    required this.id,
    required this.userId,
    required this.name,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.track,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  String name;
  int distance;
  int? ascent;
  int? descent;
  List<Position> track;
  @override
  bool deleted;

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  @override
  bool isValid() {
    return name.isNotEmpty
        && distance > 0
        && (ascent == null || ascent! >= 0)
        && (descent == null || descent! >= 0)
        && track.isNotEmpty
        && !deleted;

  }
}

class DbRouteSerializer implements DbSerializer<Route> {
  @override
  Route fromDbRecord(DbRecord r) {
    return Route(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      name: r[Keys.name]! as String,
      distance: r[Keys.distance]! as int,
      ascent: r[Keys.ascent] as int?,
      descent: r[Keys.descent] as int?,
      track: const DbPositionListConverter().mapToDart(r[Keys.track]! as Uint8List)!,
      deleted: r[Keys.deleted] == 1,
    );
  }

  @override
  DbRecord toDbRecord(Route o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.name: o.name,
      Keys.distance: o.distance,
      Keys.ascent: o.ascent,
      Keys.descent: o.descent,
      Keys.track: const DbPositionListConverter().mapToSql(o.track)!,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}