
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/id_serialization.dart';
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
}