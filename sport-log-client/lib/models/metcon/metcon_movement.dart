import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

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
class MetconMovement extends AtomicEntity {
  MetconMovement({
    required this.id,
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
    required this.count,
    required this.maleWeight,
    required this.femaleWeight,
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
  double? maleWeight;
  double? femaleWeight;
  DistanceUnit? distanceUnit;
  @override
  bool deleted;

  MetconMovement.defaultValue({
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
  })  : id = randomId(),
        count = 1,
        distanceUnit = DistanceUnit.m,
        deleted = false;

  factory MetconMovement.fromJson(Map<String, dynamic> json) =>
      _$MetconMovementFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetconMovementToJson(this);

  @override
  MetconMovement clone() => MetconMovement(
        id: id.clone(),
        metconId: metconId.clone(),
        movementId: movementId.clone(),
        movementNumber: movementNumber,
        count: count,
        maleWeight: maleWeight,
        femaleWeight: femaleWeight,
        distanceUnit: distanceUnit,
        deleted: deleted,
      );

  @override
  bool isValid() {
    return validate(!deleted, 'MetconMovement: deleted == true') &&
        validate(movementNumber >= 0, 'MetconMovement: movement number < 0') &&
        validate(count > 0, 'MetconMovement: count <= 0') &&
        validate(
          maleWeight == null || maleWeight! > 0,
          'MetconMovement: maleWeight <= 0',
        ) &&
        validate(
          femaleWeight == null || femaleWeight! > 0,
          'MetconMovement: femaleWeight <= 0',
        );
  }

  @override
  void setEmptyToNull() {}
}

class DbMetconMovementSerializer extends DbSerializer<MetconMovement> {
  @override
  MetconMovement fromDbRecord(DbRecord r, {String prefix = ''}) {
    return MetconMovement(
      id: Int64(r[prefix + Columns.id]! as int),
      metconId: Int64(r[prefix + Columns.metconId]! as int),
      movementId: Int64(r[prefix + Columns.movementId]! as int),
      movementNumber: r[prefix + Columns.movementNumber]! as int,
      count: r[prefix + Columns.count]! as int,
      maleWeight: r[prefix + Columns.maleWeight] as double?,
      femaleWeight: r[prefix + Columns.femaleWeight] as double?,
      distanceUnit: r[prefix + Columns.distanceUnit] == null
          ? null
          : DistanceUnit.values[r[prefix + Columns.distanceUnit] as int],
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(MetconMovement o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.metconId: o.metconId.toInt(),
      Columns.movementId: o.movementId.toInt(),
      Columns.movementNumber: o.movementNumber,
      Columns.count: o.count,
      Columns.maleWeight: o.maleWeight,
      Columns.femaleWeight: o.femaleWeight,
      Columns.distanceUnit: o.distanceUnit?.index,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
