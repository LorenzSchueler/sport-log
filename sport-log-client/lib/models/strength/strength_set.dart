
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
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
  @IdConverter() Int64 strengthSessionId;
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
    return !deleted
        && setNumber >= 0
        && count > 0
        && (weight == null || weight! > 0);
  }

  String toDisplayName() {
    if (weight != null) {
      return '${count}x${weight!}kg';
    } else {
      return '${count}x';
    }
  }
}

class DbStrengthSetSerializer implements DbSerializer<StrengthSet> {
  @override
  StrengthSet fromDbRecord(DbRecord r) {
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