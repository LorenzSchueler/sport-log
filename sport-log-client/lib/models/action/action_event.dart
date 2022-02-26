import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'action_event.g.dart';

@JsonSerializable()
class ActionEvent extends AtomicEntity {
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
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
  @IdConverter()
  Int64 actionId;
  @DateTimeConverter()
  DateTime datetime;
  String? arguments;
  bool enabled;
  @override
  bool deleted;

  factory ActionEvent.fromJson(Map<String, dynamic> json) =>
      _$ActionEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActionEventToJson(this);

  @override
  bool isValid() {
    return validate(!deleted, 'ActionEvent: deleted is true');
  }
}

class DbActionEventSerializer extends DbSerializer<ActionEvent> {
  @override
  ActionEvent fromDbRecord(DbRecord r, {String prefix = ''}) {
    return ActionEvent(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
      actionId: Int64(r[prefix + Columns.actionId]! as int),
      datetime: DateTime.parse(r[prefix + Columns.datetime]! as String),
      arguments: r[prefix + Columns.arguments] as String?,
      enabled: r[prefix + Columns.enabled]! as int == 1,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(ActionEvent o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId.toInt(),
      Columns.actionId: o.actionId.toInt(),
      Columns.datetime: o.datetime.toString(),
      Columns.arguments: o.arguments,
      Columns.enabled: o.enabled ? 1 : 0,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
