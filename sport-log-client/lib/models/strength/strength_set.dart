import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/eorm.dart';

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

  factory StrengthSet.fromJson(Map<String, dynamic> json) =>
      _$StrengthSetFromJson(json);

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
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'StrengthSet: deleted == true') &&
        validate(setNumber >= 0, 'StrengthSet: setNumber < 0') &&
        validate(count >= 1, 'StrengthSet: count < 1') &&
        validate(weight == null || weight! > 0, 'StrengthSet: weight <= 0');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation();
  }

  @override
  void sanitize() {
    if (weight != null && weight! <= 0) {
      weight = null;
    }
  }

  String toDisplayName(MovementDimension dim, {bool withEorm = false}) {
    final weightStr = weight == null ? null : formatWeight(weight!);
    switch (dim) {
      case MovementDimension.reps:
        final eormVal = withEorm ? eorm(dim) : null;
        final eormStr = eormVal != null ? formatWeight(eormVal) : null;
        return weightStr != null
            ? eormStr != null
                ? '$count x $weightStr  # $eormStr'
                : '$count x $weightStr'
            : '$count reps';
      case MovementDimension.time:
        final result = Duration(milliseconds: count).formatMsMill;
        return weightStr != null ? '$result ($weightStr)' : result;
      case MovementDimension.energy:
        final result = '$count cal';
        return weightStr != null ? '$result ($weightStr)' : result;
      case MovementDimension.distance:
        final result = "$count m";
        return weightStr != null ? '$result ($weightStr)' : result;
    }
  }

  double? get volume => weight == null ? null : weight! * count.toDouble();

  double? eorm(MovementDimension movementDimension) {
    return movementDimension != MovementDimension.reps || weight == null
        ? null
        : getEorm(count, weight!);
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
