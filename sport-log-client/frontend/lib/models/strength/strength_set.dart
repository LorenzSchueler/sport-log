
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';

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
        && setNumber > 0
        && count > 0
        && (weight == null || weight! > 0);
  }
}