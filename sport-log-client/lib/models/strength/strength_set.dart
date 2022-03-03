import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/eorm.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'strength_set.g.dart';

@JsonSerializable()
class StrengthSet extends AtomicEntity {
  StrengthSet({
    required this.id,
    required this.strengthSessionId,
    required this.setNumber,
    required this.count,
    required this.weight,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 strengthSessionId;
  int setNumber;
  int count;
  double? weight;
  @override
  bool deleted;

  factory StrengthSet.fromJson(Map<String, dynamic> json) =>
      _$StrengthSetFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StrengthSetToJson(this);

  @override
  StrengthSet clone() => StrengthSet(
        id: id.clone(),
        strengthSessionId: strengthSessionId.clone(),
        setNumber: setNumber,
        count: count,
        weight: weight,
        deleted: deleted,
      );

  @override
  bool isValid() {
    return validate(!deleted, 'StrengthSet: deleted == true') &&
        validate(setNumber >= 0, 'StrengthSet: setNumber < 0') &&
        validate(count > 0, 'StrengthSet: count <= 0') &&
        validate(weight == null || weight! > 0, 'StrengthSet: weight <= 0');
  }

  String toDisplayName(MovementDimension dim) =>
      formatCountWeight(dim, count, weight);

  double? get volume => weight == null ? null : weight! * count.toDouble();

  double? get eorm {
    return weight == null ? null : getEorm(count, weight!);
  }
}

class DbStrengthSetSerializer extends DbSerializer<StrengthSet> {
  @override
  StrengthSet fromDbRecord(DbRecord r, {String prefix = ''}) {
    return StrengthSet(
      id: Int64(r[prefix + Columns.id]! as int),
      strengthSessionId: Int64(r[prefix + Columns.strengthSessionId]! as int),
      setNumber: r[prefix + Columns.setNumber]! as int,
      count: r[prefix + Columns.count]! as int,
      weight: r[prefix + Columns.weight] as double?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(StrengthSet o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.strengthSessionId: o.strengthSessionId.toInt(),
      Columns.setNumber: o.setNumber,
      Columns.count: o.count,
      Columns.weight: o.weight,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
