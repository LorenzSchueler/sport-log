import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';

part 'route.g.dart';

@JsonSerializable()
class Route extends DbObject with Comparable<Route> {
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
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
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
    return validate(name.isNotEmpty, 'Route: name is empty') &&
        validate(distance > 0, 'Route: distance <= 0') &&
        validate(ascent == null || ascent! >= 0, 'Route: ascent < 0') &&
        validate(descent == null || descent! >= 0, 'Route: descent < 0') &&
        validate(track.isNotEmpty, 'Route: track is empty') &&
        validate(!deleted, 'Route: deleted == true');
  }

  @override
  int compareTo(Route other) {
    return name.compareTo(other.name);
  }
}

class DbRouteSerializer implements DbSerializer<Route> {
  @override
  Route fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Route(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      name: r[Keys.name]! as String,
      distance: r[Keys.distance]! as int,
      ascent: r[Keys.ascent] as int?,
      descent: r[Keys.descent] as int?,
      track: const DbPositionListConverter()
          .mapToDart(r[Keys.track]! as Uint8List)!,
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
