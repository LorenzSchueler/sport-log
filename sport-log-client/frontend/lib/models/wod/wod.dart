
import 'package:json_annotation/json_annotation.dart';

part 'wod.g.dart';

@JsonSerializable()
class Wod {
  Wod({
    required this.id,
    required this.userId,
    required this.date,
    required this.description,
  });

  int id;
  int userId;
  DateTime date;
  String? description;

  factory Wod.fromMap(Map<String, dynamic> json) => _$WodFromJson(json);
  Map<String, dynamic> toJson() => _$WodToJson(this);
}