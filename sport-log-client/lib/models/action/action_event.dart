import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

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

  ActionEvent.defaultValue(this.actionId)
      : id = randomId(),
        userId = Settings.instance.userId!,
        datetime = DateTime.now(),
        arguments = null,
        enabled = true,
        deleted = false;

  factory ActionEvent.fromJson(Map<String, dynamic> json) =>
      _$ActionEventFromJson(json);

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

  @override
  Map<String, dynamic> toJson() => _$ActionEventToJson(this);

  @override
  ActionEvent clone() => ActionEvent(
        id: id.clone(),
        userId: userId.clone(),
        actionId: actionId.clone(),
        datetime: datetime.clone(),
        arguments: arguments,
        enabled: enabled,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitazion() {
    return validate(!deleted, 'ActionEvent: deleted is true');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        validate(
          arguments == null || arguments!.isNotEmpty,
          'ActionEvent: arguments are empty but not null',
        );
  }

  @override
  void sanitize() {
    if (arguments != null && arguments!.isEmpty) {
      arguments = null;
    }
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
