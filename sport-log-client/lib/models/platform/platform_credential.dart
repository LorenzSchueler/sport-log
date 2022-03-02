import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'platform_credential.g.dart';

@JsonSerializable()
class PlatformCredential extends AtomicEntity {
  PlatformCredential({
    required this.id,
    required this.userId,
    required this.platformId,
    required this.username,
    required this.password,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @IdConverter()
  Int64 userId;
  @IdConverter()
  Int64 platformId;
  String username;
  String password;
  @override
  bool deleted;

  factory PlatformCredential.fromJson(Map<String, dynamic> json) =>
      _$PlatformCredentialFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlatformCredentialToJson(this);

  @override
  PlatformCredential clone() => PlatformCredential.fromJson(toJson());

  @override
  bool isValid() {
    return validate(!deleted, 'PlatformCredential: deleted == true') &&
        validate(
          username.isNotEmpty,
          'PlatformCredential: username is empty',
        ) &&
        validate(password.isNotEmpty, 'PlatformCredential: password is empty');
  }
}

class DbPlatformCredentialSerializer extends DbSerializer<PlatformCredential> {
  @override
  PlatformCredential fromDbRecord(DbRecord r, {String prefix = ''}) {
    return PlatformCredential(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: Int64(r[prefix + Columns.userId]! as int),
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
      Columns.userId: o.userId.toInt(),
      Columns.platformId: o.platformId.toInt(),
      Columns.username: o.username,
      Columns.password: o.password,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
