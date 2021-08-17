
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/models/action/naive_time.dart';
import 'package:sport_log/models/action/weekday.dart';

part 'action_rule.g.dart';

@JsonSerializable()
class ActionRule implements DbObject {
  ActionRule({
    required this.id,
    required this.userId,
    required this.actionId,
    required this.weekday,
    required this.time,
    required this.enabled,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 actionId;
  Weekday weekday;
  @NaiveTimeSerde() NaiveTime time;
  bool enabled;
  @override
  bool deleted;

  factory ActionRule.fromJson(Map<String, dynamic> json) => _$ActionRuleFromJson(json);
  Map<String, dynamic> toJson() => _$ActionRuleToJson(this);

  @override
  bool isValid() {
    return !deleted;
  }
}