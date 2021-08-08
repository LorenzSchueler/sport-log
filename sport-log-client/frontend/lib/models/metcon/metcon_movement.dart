
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'metcon_movement.g.dart';

@JsonSerializable()
class MetconMovement {
  MetconMovement({
    required this.id,
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
    required this.count,
    required this.unit,
    required this.weight,
  });

  int id;
  int metconId;
  int movementId;
  int movementNumber;
  int count;
  MovementUnit unit;
  double? weight;

  factory MetconMovement.fromJson(Map<String, dynamic> json) => _$MetconMovementFromJson(json);
  Map<String, dynamic> toJson() => _$MetconMovementToJson(this);
}