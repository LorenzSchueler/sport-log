import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
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

  factory ActionProvider.fromJson(Map<String, dynamic> json) =>
      _$ActionProviderFromJson(json);

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

  @override
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);

  @override
  ActionProvider clone() => ActionProvider(
        id: id.clone(),
        name: name,
        password: password,
        platformId: platformId.clone(),
        description: description,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'ActionProvider: deleted is true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'ActionProvider: name.length is < 2 or > 80',
        ) &&
        validate(
          password.length >= 2 && password.length <= 96,
          'ActionProvider: password.length is < 2 or > 96',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          description == null || description!.isNotEmpty,
          'ActionProvider: description is empty but not null',
        );
  }

  @override
  void sanitize() {
    if (description != null && description!.isEmpty) {
      description = null;
    }
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
