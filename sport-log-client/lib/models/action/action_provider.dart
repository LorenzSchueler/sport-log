import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'action_provider.g.dart';

@JsonSerializable(constructor: "_")
class ActionProvider extends AtomicEntity {
  /// ActionProviders should never be created.
  ActionProvider._({
    required this.id,
    required this.name,
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
  @IdConverter()
  Int64 platformId;
  String? description;
  @override
  bool deleted;

  @override
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);

  @override
  ActionProvider clone() => ActionProvider._(
        id: id.clone(),
        name: name,
        platformId: platformId.clone(),
        description: description,
        deleted: deleted,
      );

  /// ActionProviders should never be created.
  @override
  bool isValidBeforeSanitation() => true;

  /// ActionProviders should never be created.
  @override
  bool isValid() => true;

  /// ActionProviders should never be created.
  @override
  void sanitize() {}
}

class DbActionProviderSerializer extends DbSerializer<ActionProvider> {
  @override
  ActionProvider fromDbRecord(DbRecord r, {String prefix = ''}) {
    return ActionProvider._(
      id: Int64(r[prefix + Columns.id]! as int),
      name: r[prefix + Columns.name]! as String,
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
      Columns.platformId: o.platformId.toInt(),
      Columns.description: o.description,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
