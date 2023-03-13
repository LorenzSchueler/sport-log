import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'platform.g.dart';

@JsonSerializable(constructor: "_")
class Platform extends AtomicEntity {
  /// Platforms should never be created.
  Platform._({
    required this.id,
    required this.name,
    required this.credential,
    required this.deleted,
  });

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  String name;
  bool credential;
  @override
  bool deleted;

  @override
  Map<String, dynamic> toJson() => _$PlatformToJson(this);

  @override
  Platform clone() => Platform._(
        id: id.clone(),
        name: name,
        credential: credential,
        deleted: deleted,
      );

  /// Platforms should never be created.
  @override
  bool isValidBeforeSanitation() => true;

  /// Platforms should never be created.
  @override
  bool isValid() => true;

  /// Platforms should never be created.
  @override
  void sanitize() {}
}

class DbPlatformSerializer extends DbSerializer<Platform> {
  @override
  Platform fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Platform._(
      id: Int64(r[prefix + Columns.id]! as int),
      name: r[prefix + Columns.name]! as String,
      credential: r[prefix + Columns.credential]! as int == 1,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Platform o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.name: o.name,
      Columns.credential: o.credential ? 1 : 0,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
