import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'platform.g.dart';

@JsonSerializable()
class Platform extends Entity {
  Platform({
    required this.id,
    required this.name,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  String name;
  @override
  bool deleted;

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlatformToJson(this);

  @override
  bool isValid() {
    return validate(name.isNotEmpty, 'Platform: name is empty') &&
        validate(!deleted, 'Platform: deleted == true');
  }
}

class DbPlatformSerializer implements DbSerializer<Platform> {
  @override
  Platform fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Platform(
        id: Int64(r[Columns.id]! as int),
        name: r[Columns.name]! as String,
        deleted: r[Columns.deleted]! as int == 1);
  }

  @override
  DbRecord toDbRecord(Platform o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.name: o.name,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
