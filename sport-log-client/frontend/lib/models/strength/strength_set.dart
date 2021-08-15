
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/helpers/update_validatable.dart';

part 'strength_set.g.dart';

@JsonSerializable()
class StrengthSet extends Insertable implements UpdateValidatable {
  StrengthSet({
    required this.id,
    required this.strengthSessionId,
    required this.setNumber,
    required this.count,
    required this.weight,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 strengthSessionId;
  int setNumber;
  int count;
  double? weight;
  bool deleted;

  factory StrengthSet.fromJson(Map<String, dynamic> json) => _$StrengthSetFromJson(json);
  Map<String, dynamic> toJson() => _$StrengthSetToJson(this);

  @override
  bool validateOnUpdate() {
    return !deleted
        && setNumber > 0
        && count > 0
        && (weight == null || weight! > 0);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return StrengthSetsCompanion(
      id: Value(id),
      strengthSessionId: Value(id),
      setNumber: Value(setNumber),
      count: Value(count),
      weight: Value(weight),
      deleted: Value(deleted),
    ).toColumns(false);
  }
}