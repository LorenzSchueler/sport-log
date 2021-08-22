
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';
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
    required this.arguments,
    required this.enabled,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 actionId;
  Weekday weekday;
  @DateTimeConverter() DateTime time;
  String? arguments;
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

class DbActionRuleSerializer implements DbSerializer<ActionRule> {
  @override
  ActionRule fromDbRecord(DbRecord r) {
    return ActionRule(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      actionId: Int64(r[Keys.actionId]! as int),
      weekday: Weekday.values[r[Keys.weekday]! as int],
      time: DateTime.parse(r[Keys.time]! as String),
      arguments: r[Keys.arguments] as String?,
      enabled: r[Keys.enabled]! as int == 1,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(ActionRule o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.actionId: o.actionId.toInt(),
      Keys.weekday: Weekday.values.indexOf(o.weekday),
      Keys.time: o.time.toString(),
      Keys.arguments: o.arguments,
      Keys.enabled: o.enabled ? 1 : 0,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}