import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'strength_set.g.dart';

@JsonSerializable()
class StrengthSet implements DbObject {
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

  Map<String, dynamic> toJson() => _$StrengthSetToJson(this);

  @override
  bool isValid() {
    return validate(!deleted, 'StrengthSet: deleted == true') &&
        validate(setNumber >= 0, 'StrengthSet: setNumber < 0') &&
        validate(count > 0, 'StrengthSet: count <= 0') &&
        validate(weight == null || weight! > 0, 'StrengthSet: weight <= 0');
  }

  String toDisplayName() {
    if (weight != null) {
      return '${count}x${(weight! * 10).roundToDouble() / 10}kg';
    } else {
      return '${count}x';
    }
  }

  double? get volume => weight == null ? null : weight! * count.toDouble();

  static const eormMapping = {
    1: 1.0,
    2: 0.97,
    3: 0.94,
    4: 0.92,
    5: 0.89,
    6: 0.86,
    7: 0.83,
    8: 0.81,
    9: 0.78,
    10: 0.75,
    11: 0.73,
    12: 0.71,
    13: 0.70,
    14: 0.68,
    15: 0.67,
    16: 0.65,
    17: 0.64,
    18: 0.63,
    19: 0.61,
    20: 0.60,
    21: 0.59,
    22: 0.58,
    23: 0.57,
    24: 0.56,
    25: 0.55,
    26: 0.54,
    27: 0.53,
    28: 0.52,
    29: 0.51,
    30: 0.50,
  };

  double? get eorm {
    if (weight == null) return null;
    final percentage = eormMapping[count];
    return percentage == null ? null : weight! / percentage;
  }
}

class DbStrengthSetSerializer implements DbSerializer<StrengthSet> {
  @override
  StrengthSet fromDbRecord(DbRecord r, {String prefix = ''}) {
    return StrengthSet(
      id: Int64(r[Keys.id]! as int),
      strengthSessionId: Int64(r[Keys.strengthSessionId]! as int),
      setNumber: r[Keys.setNumber]! as int,
      count: r[Keys.count]! as int,
      weight: r[Keys.weight] as double?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(StrengthSet o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.strengthSessionId: o.strengthSessionId.toInt(),
      Keys.setNumber: o.setNumber,
      Keys.count: o.count,
      Keys.weight: o.weight,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
