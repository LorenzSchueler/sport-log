import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'action_provider.g.dart';

@JsonSerializable()
class ActionProvider extends AtomicEntity {
  ActionProvider({
    required this.id,
    required this.name,
    required this.password,
    required this.platformId,
    required this.description,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  String name;
  String password;
  @IdConverter()
  Int64 platformId;
  String? description;
  @override
  bool deleted;

  factory ActionProvider.fromJson(Map<String, dynamic> json) =>
      _$ActionProviderFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);

  @override
  bool isValid() {
    return validate(name.isNotEmpty, 'ActionProvider: name is empty') &&
        validate(password.isNotEmpty, 'ActionProvider: password is empty') &&
        validate(!deleted, 'ActionProvider: deleted is true');
  }
}

class DbActionProviderSerializer extends DbSerializer<ActionProvider> {
  @override
  ActionProvider fromDbRecord(DbRecord r, {String prefix = ''}) {
    return ActionProvider(
      id: Int64(r[prefix + Columns.id]! as int),
      name: r[prefix + Columns.name]! as String,
      password: r[prefix + Columns.password]! as String,
      platformId: Int64(r[prefix + Columns.platformId]! as int),
      description: r[prefix + Columns.description] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(ActionProvider o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.name: o.name,
      Columns.password: o.password,
      Columns.platformId: o.platformId.toInt(),
      Columns.description: o.description,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
