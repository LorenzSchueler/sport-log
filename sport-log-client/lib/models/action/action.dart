import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
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

  @override
  @IdConverter()
  Int64 id;
  String name;
  @IdConverter()
  Int64 actionProviderId;
  String? description;
  int createBefore;
  int deleteAfter;
  @override
  bool deleted;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActionToJson(this);

  @override
  bool isValid() {
    return validate(name.isNotEmpty, 'Action: name is empty') &&
        validate(!deleted, 'Action: deleted is true');
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
      createBefore: r[prefix + Columns.createBefore]! as int,
      deleteAfter: r[prefix + Columns.deleteAfter]! as int,
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
      Columns.createBefore: o.createBefore,
      Columns.deleteAfter: o.deleteAfter,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
