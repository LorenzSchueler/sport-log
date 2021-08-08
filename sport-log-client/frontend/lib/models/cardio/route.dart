
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/cardio/position.dart';

part 'route.g.dart';

@JsonSerializable()
class Route {
  Route({
    required this.id,
    required this.userId,
    required this.name,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.track,
  });

  int id;
  int userId;
  String name;
  int distance;
  int? ascent;
  int? descent;
  List<Position>? track;

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);
}