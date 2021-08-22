
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'action_provider.g.dart';

@JsonSerializable()
class ActionProvider implements DbObject {
  ActionProvider({
    required this.id,
    required this.name,
    required this.password,
    required this.platformId,
    required this.description,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  String name;
  String password;
  @IdConverter() Int64 platformId;
  String? description;
  @override
  bool deleted;

  factory ActionProvider.fromJson(Map<String, dynamic> json) => _$ActionProviderFromJson(json);
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);

  @override
  bool isValid() {
    return name.isNotEmpty && password.isNotEmpty && !deleted;
  }
}

class DbActionProviderSerializer implements DbSerializer<ActionProvider> {
  @override
  ActionProvider fromDbRecord(DbRecord r) {
    return ActionProvider(
      id: Int64(r[Keys.id]! as int),
      name: r[Keys.name]! as String,
      password: r[Keys.password]! as String,
      platformId: Int64(r[Keys.platformId]! as int),
      description: r[Keys.description] as String?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(ActionProvider o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.name: o.name,
      Keys.password: o.password,
      Keys.platformId: o.platformId.toInt(),
      Keys.description: o.description,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}