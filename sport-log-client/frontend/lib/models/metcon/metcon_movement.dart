
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'metcon_movement.g.dart';

@JsonSerializable()
class MetconMovement implements DbObject {
  MetconMovement({
    required this.id,
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
    required this.count,
    required this.unit,
    required this.weight,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 metconId;
  @IdConverter() Int64 movementId;
  int movementNumber;
  int count;
  MovementUnit unit;
  double? weight;
  @override
  bool deleted;

  factory MetconMovement.fromJson(Map<String, dynamic> json) => _$MetconMovementFromJson(json);
  Map<String, dynamic> toJson() => _$MetconMovementToJson(this);

  @override
  bool isValid() {
    return deleted != true
        && movementNumber > 0
        && count > 0
        && (weight == null || weight! > 0);
  }
}