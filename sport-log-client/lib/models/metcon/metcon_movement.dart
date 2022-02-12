import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'metcon_movement.g.dart';

enum DistanceUnit {
  @JsonValue('Meter')
  m,
  @JsonValue('Km')
  km,
  @JsonValue('Yard')
  yards,
  @JsonValue('Foot')
  feet,
  @JsonValue('Mile')
  miles,
}

extension DisplayName on DistanceUnit {
  String get displayName {
    switch (this) {
      case DistanceUnit.m:
        return 'm';
      case DistanceUnit.km:
        return 'km';
      case DistanceUnit.yards:
        return 'yard';
      case DistanceUnit.feet:
        return 'ft';
      case DistanceUnit.miles:
        return 'miles';
    }
  }
}

@JsonSerializable()
class MetconMovement extends Entity {
  MetconMovement({
    required this.id,
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
    required this.count,
    required this.weight,
    required this.distanceUnit,
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
  DistanceUnit? distanceUnit;
  @override
  bool deleted;

  MetconMovement.defaultValue({
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
  })  : id = randomId(),
        count = 1,
        weight = null,
        distanceUnit = DistanceUnit.m,
        deleted = false;

  factory MetconMovement.fromJson(Map<String, dynamic> json) =>
      _$MetconMovementFromJson(json);

  @override
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
      id: Int64(r[prefix + Keys.id]! as int),
      metconId: Int64(r[prefix + Keys.id]! as int),
      movementId: Int64(r[prefix + Keys.movementId]! as int),
      movementNumber: r[prefix + Keys.movementNumber]! as int,
      count: r[prefix + Keys.count]! as int,
      weight: r[prefix + Keys.weight] as double?,
      distanceUnit: r[prefix + Keys.distanceUnit] == null
          ? null
          : DistanceUnit.values[r[prefix + Keys.distanceUnit] as int],
      deleted: r[prefix + Keys.deleted]! as int == 1,
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
      Keys.distanceUnit: o.distanceUnit?.index,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
