
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
    required this.movementUnit,
    required this.weight,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 metconId;
  @IdConverter() Int64 movementId;
  int movementNumber;
  int count;
  MovementUnit movementUnit;
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

class DbMetconMovementSerializer implements DbSerializer<MetconMovement> {
  @override
  MetconMovement fromDbRecord(DbRecord r) {
    return MetconMovement(
      id: Int64(r[Keys.id]! as int),
      metconId: Int64(r[Keys.id]! as int),
      movementId: Int64(r[Keys.movementId]! as int),
      movementNumber: r[Keys.movementNumber]! as int,
      count: r[Keys.count]! as int,
      movementUnit: MovementUnit.values[r[Keys.movementUnit]! as int],
      weight: r[Keys.weight] as double?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(MetconMovement o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.metconId: o.metconId.toInt(),
      Keys.movementId: o.movementId.toInt(),
      Keys.movementNumber: o.movementNumber,
      Keys.count: o.count,
      Keys.movementUnit: MovementUnit.values.indexOf(o.movementUnit),
      Keys.weight: o.weight,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}