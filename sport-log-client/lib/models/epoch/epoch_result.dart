import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'epoch_result.g.dart';

@JsonSerializable()
class EpochResult {
  EpochResult({required this.epoch});

  factory EpochResult.fromJson(Map<String, dynamic> json) =>
      _$EpochResultFromJson(json);

  @IdConverter()
  Int64 epoch;

  Map<String, dynamic> toJson() => _$EpochResultToJson(this);
}
