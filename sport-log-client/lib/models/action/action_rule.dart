import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/action/weekday.dart';

part 'action_rule.g.dart';

@JsonSerializable()
class ActionRule extends Entity {
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
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
  @IdConverter()
  Int64 actionId;
  Weekday weekday;
  @DateTimeConverter()
  DateTime time;
  String? arguments;
  bool enabled;
  @override
  bool deleted;

  factory ActionRule.fromJson(Map<String, dynamic> json) =>
      _$ActionRuleFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActionRuleToJson(this);

  @override
  bool isValid() {
    return validate(!deleted, 'ActionRule: deleted is true');
  }
}

class DbActionRuleSerializer implements DbSerializer<ActionRule> {
  @override
  ActionRule fromDbRecord(DbRecord r, {String prefix = ''}) {
    return ActionRule(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
      actionId: Int64(r[prefix + Columns.actionId]! as int),
      weekday: Weekday.values[r[prefix + Columns.weekday]! as int],
      time: DateTime.parse(r[prefix + Columns.time]! as String),
      arguments: r[prefix + Columns.arguments] as String?,
      enabled: r[prefix + Columns.enabled]! as int == 1,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(ActionRule o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId.toInt(),
      Columns.actionId: o.actionId.toInt(),
      Columns.weekday: o.weekday.index,
      Columns.time: o.time.toString(),
      Columns.arguments: o.arguments,
      Columns.enabled: o.enabled ? 1 : 0,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
