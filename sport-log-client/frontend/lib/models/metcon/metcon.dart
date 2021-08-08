
import 'package:json_annotation/json_annotation.dart';

part 'metcon.g.dart';

enum MetconType {
  @JsonValue("Amrap") amrap,
  @JsonValue("Emom") emom,
  @JsonValue("ForTime") forTime
}

@JsonSerializable()
class Metcon {
  Metcon({
    required this.id,
    required this.userId,
    required this.name,
    required this.metconType,
    required this.rounds,
    required this.timecap,
    required this.description,
  });

  int id;
  int? userId;
  String? name;
  MetconType metconType;
  int? rounds;
  int? timecap;
  String? description;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);
  Map<String, dynamic> toJson() => _$MetconToJson(this);
}