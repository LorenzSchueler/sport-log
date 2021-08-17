
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';
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
  List<Position>? track;
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
        && (track == null || track!.isNotEmpty)
        && !deleted;

  }
}