import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'platform.g.dart';

@JsonSerializable()
class Platform extends AtomicEntity {
  Platform({
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
  Platform clone() => Platform(
        id: id.clone(),
        name: name,
        credential: credential,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitazion() {
    return validate(!deleted, 'Platform: deleted == true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Platform: name.length is < 2 or > 80',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion();
  }

  @override
  void sanitize() {}
}

class DbPlatformSerializer extends DbSerializer<Platform> {
  @override
  Platform fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Platform(
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
