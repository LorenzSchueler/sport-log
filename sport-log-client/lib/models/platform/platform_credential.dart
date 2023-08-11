import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

part 'platform_credential.g.dart';

@JsonSerializable()
class PlatformCredential extends AtomicEntity {
  PlatformCredential({
    required this.id,
    required this.platformId,
    required this.username,
    required this.password,
    required this.deleted,
  });

  PlatformCredential.defaultValue(this.platformId)
      : id = randomId(),
        username = "",
        password = "",
        deleted = false;

  factory PlatformCredential.fromJson(Map<String, dynamic> json) =>
      _$PlatformCredentialFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @JsonKey(includeToJson: true, name: "user_id")
  @IdConverter()
  Int64 get _userId => Settings.instance.userId!;
  @IdConverter()
  Int64 platformId;
  String username;
  String password;
  @override
  bool deleted;

  @override
  Map<String, dynamic> toJson() => _$PlatformCredentialToJson(this);

  @override
  PlatformCredential clone() => PlatformCredential(
        id: id.clone(),
        platformId: platformId.clone(),
        username: username,
        password: password,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'PlatformCredential: deleted == true') &&
        validate(
          username.length <= 80,
          'PlatformCredential: username.length > 80',
        ) &&
        validate(
          password.length <= 80,
          'PlatformCredential: password.length > 80',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation();
  }

  @override
  void sanitize() {}
}

class DbPlatformCredentialSerializer extends DbSerializer<PlatformCredential> {
  @override
  PlatformCredential fromDbRecord(DbRecord r, {String prefix = ''}) {
    return PlatformCredential(
      id: Int64(r[prefix + Columns.id]! as int),
      platformId: Int64(r[prefix + Columns.platformId]! as int),
      username: r[prefix + Columns.username]! as String,
      password: r[prefix + Columns.password]! as String,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(PlatformCredential o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.platformId: o.platformId.toInt(),
      Columns.username: o.username,
      Columns.password: o.password,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
