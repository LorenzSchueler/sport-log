
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'action_event.g.dart';

@JsonSerializable()
class ActionEvent implements DbObject {
  ActionEvent({
    required this.id,
    required this.userId,
    required this.actionId,
    required this.datetime,
    required this.arguments,
    required this.enabled,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 actionId;
  @DateTimeConverter() DateTime datetime;
  String? arguments;
  bool enabled;
  @override
  bool deleted;

  factory ActionEvent.fromJson(Map<String, dynamic> json) => _$ActionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ActionEventToJson(this);

  @override
  bool isValid() {
    return !deleted;
  }
}

class DbActionEventSerializer implements DbSerializer<ActionEvent> {
  @override
  ActionEvent fromDbRecord(DbRecord r) {
    return ActionEvent(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      actionId: Int64(r[Keys.actionId]! as int),
      datetime: DateTime.parse(r[Keys.datetime]! as String),
      arguments: r[Keys.arguments] as String?,
      enabled: r[Keys.enabled]! as int == 1,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(ActionEvent o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.actionId: o.actionId.toInt(),
      Keys.datetime: o.datetime.toString(),
      Keys.arguments: o.arguments,
      Keys.enabled: o.enabled ? 1 : 0,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}