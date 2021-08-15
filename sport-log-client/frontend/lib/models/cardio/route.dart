
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/helpers/update_validatable.dart';

part 'route.g.dart';

@JsonSerializable()
class Route extends Insertable implements UpdateValidatable {
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

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  String name;
  int distance;
  int? ascent;
  int? descent;
  List<Position>? track;
  bool deleted;

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return RoutesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      distance: Value(distance),
      ascent: Value(ascent),
      descent: Value(descent),
      track: Value(track),
      deleted: Value(deleted),
    ).toColumns(false);
  }

  @override
  bool validateOnUpdate() {
    return name.isNotEmpty
        && distance > 0
        && (ascent == null || ascent! >= 0)
        && (descent == null || descent! >= 0)
        && (track == null || track!.isNotEmpty)
        && !deleted;

  }
}