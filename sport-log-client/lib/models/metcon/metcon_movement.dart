import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'metcon_movement.g.dart';

@JsonSerializable()
class MetconMovement implements DbObject {
  MetconMovement({
    required this.id,
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
    required this.count,
    required this.weight,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 metconId;
  @IdConverter()
  Int64 movementId;
  int movementNumber;
  int count;
  double? weight;
  @override
  bool deleted;

  MetconMovement.defaultValue({
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
  })  : id = randomId(),
        count = 1,
        weight = null,
        deleted = false;

  factory MetconMovement.fromJson(Map<String, dynamic> json) =>
      _$MetconMovementFromJson(json);

  Map<String, dynamic> toJson() => _$MetconMovementToJson(this);

  @override
  bool isValid() {
    return validate(deleted != true, 'MetconMovement: deleted == true') &&
        validate(movementNumber >= 0, 'MetconMovement: movement number < 0') &&
        validate(count > 0, 'MetconMovement: count <= 0') &&
        validate(weight == null || weight! > 0, 'MetconMovement: weight <= 0');
  }
}

class DbMetconMovementSerializer implements DbSerializer<MetconMovement> {
  @override
  MetconMovement fromDbRecord(DbRecord r, {String prefix = ''}) {
    return MetconMovement(
      id: Int64(r[Keys.id]! as int),
      metconId: Int64(r[Keys.id]! as int),
      movementId: Int64(r[Keys.movementId]! as int),
      movementNumber: r[Keys.movementNumber]! as int,
      count: r[Keys.count]! as int,
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
      Keys.weight: o.weight,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
