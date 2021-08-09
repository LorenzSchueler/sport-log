
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/id_serialization.dart';

part 'strength_set.g.dart';

@JsonSerializable()
class StrengthSet {
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
}