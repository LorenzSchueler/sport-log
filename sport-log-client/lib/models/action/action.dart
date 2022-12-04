import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'action.g.dart';

@JsonSerializable()
class Action extends AtomicEntity {
  Action({
    required this.id,
    required this.name,
    required this.actionProviderId,
    required this.description,
    required this.createBefore,
    required this.deleteAfter,
    required this.deleted,
  });

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  String name;
  @IdConverter()
  Int64 actionProviderId;
  String? description;
  @DurationConverter()
  Duration createBefore;
  @DurationConverter()
  Duration deleteAfter;
  @override
  bool deleted;

  @override
  Map<String, dynamic> toJson() => _$ActionToJson(this);

  @override
  Action clone() => Action(
        id: id.clone(),
        name: name,
        actionProviderId: actionProviderId.clone(),
        description: description,
        createBefore: createBefore.clone(),
        deleteAfter: deleteAfter.clone(),
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'Action: deleted is true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Action: name.length < 2 or > 80',
        ) &&
        validate(
          createBefore > Duration.zero,
          'Action: createBefore < 0',
        ) &&
        validate(
          deleteAfter > Duration.zero,
          'Action: deleteAfter < 0',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          description == null || description!.isNotEmpty,
          'Action: description is empty but not null',
        );
  }

  @override
  void sanitize() {
    if (description != null && description!.isEmpty) {
      description = null;
    }
  }
}

class DbActionSerializer extends DbSerializer<Action> {
  @override
  Action fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Action(
      id: Int64(r[prefix + Columns.id]! as int),
      name: r[prefix + Columns.name]! as String,
      actionProviderId: Int64(r[prefix + Columns.actionProviderId]! as int),
      description: r[prefix + Columns.description] as String?,
      createBefore:
          Duration(milliseconds: r[prefix + Columns.createBefore]! as int),
      deleteAfter:
          Duration(milliseconds: r[prefix + Columns.deleteAfter]! as int),
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Action o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.name: o.name,
      Columns.actionProviderId: o.actionProviderId.toInt(),
      Columns.description: o.description,
      Columns.createBefore: o.createBefore.inMilliseconds,
      Columns.deleteAfter: o.deleteAfter.inMilliseconds,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
