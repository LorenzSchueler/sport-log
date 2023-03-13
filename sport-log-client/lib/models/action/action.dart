import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'action.g.dart';

@JsonSerializable(constructor: "_")
class Action extends AtomicEntity {
  /// Actions should never be created.
  Action._({
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
  Action clone() => Action._(
        id: id.clone(),
        name: name,
        actionProviderId: actionProviderId.clone(),
        description: description,
        createBefore: createBefore.clone(),
        deleteAfter: deleteAfter.clone(),
        deleted: deleted,
      );

  /// Actions should never be created.
  @override
  bool isValidBeforeSanitation() => true;

  /// Actions should never be created.
  @override
  bool isValid() => true;

  /// Actions should never be created.
  @override
  void sanitize() {}
}

class DbActionSerializer extends DbSerializer<Action> {
  @override
  Action fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Action._(
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
