
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'action.g.dart';

@JsonSerializable()
class Action implements DbObject {
  Action({
    required this.id,
    required this.name,
    required this.actionProviderId,
    required this.description,
    required this.createBefore,
    required this.deleteAfter,
    required this.deleted,
  });

  @override @IdConverter() Int64 id;
  String name;
  @IdConverter() Int64 actionProviderId;
  String? description;
  int createBefore;
  int deleteAfter;
  @override bool deleted;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
  Map<String, dynamic> toJson() => _$ActionToJson(this);

  @override
  bool isValid() {
    return name.isNotEmpty && !deleted;
  }
}

class DbActionSerializer implements DbSerializer<Action> {

  @override
  Action fromDbRecord(DbRecord r) {
    return Action(
      id: Int64(r[Keys.id]! as int),
      name: r[Keys.name]! as String,
      actionProviderId: Int64(r[Keys.actionProviderId]! as int),
      description: r[Keys.description] as String?,
      createBefore: r[Keys.createBefore]! as int,
      deleteAfter: r[Keys.deleteAfter]! as int,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Action o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.name: o.name,
      Keys.actionProviderId: o.actionProviderId,
      Keys.description: o.description,
      Keys.createBefore: o.createBefore,
      Keys.deleteAfter: o.deleteAfter,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}