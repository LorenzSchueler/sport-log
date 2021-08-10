
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_serialization.dart';
import 'package:sport_log/models/update_validatable.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'metcon_movement.g.dart';

@JsonSerializable()
class MetconMovement extends Insertable<MetconMovement> implements UpdateValidatable {
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

  @IdConverter() Int64 id;
  @IdConverter() Int64 metconId;
  @IdConverter() Int64 movementId;
  int movementNumber;
  int count;
  MovementUnit unit;
  double? weight;
  bool deleted;

  factory MetconMovement.fromJson(Map<String, dynamic> json) => _$MetconMovementFromJson(json);
  Map<String, dynamic> toJson() => _$MetconMovementToJson(this);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return MetconMovementsCompanion(
      id: Value(id),
      metconId: Value(metconId),
      movementId: Value(movementId),
      movementNumber: Value(movementNumber),
      count: Value(count),
      unit: Value(unit),
      weight: Value(weight),
      deleted: Value(deleted),
    ).toColumns(false);
  }

  @override
  bool validateOnUpdate() {
    return deleted != true
        && movementNumber > 0
        && count > 0
        && (weight == null || weight! > 0);
  }
}