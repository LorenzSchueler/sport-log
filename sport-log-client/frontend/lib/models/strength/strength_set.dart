
import 'package:json_annotation/json_annotation.dart';

part 'strength_set.g.dart';

@JsonSerializable()
class StrengthSet {
  StrengthSet({
    required this.id,
    required this.strengthSessionId,
    required this.setNumber,
    required this.count,
    required this.weight,
  });

  int id;
  int strengthSessionId;
  int setNumber;
  int count;
  double? weight;

  factory StrengthSet.fromJson(Map<String, dynamic> json) => _$StrengthSetFromJson(json);
  Map<String, dynamic> toJson() => _$StrengthSetToJson(this);
}