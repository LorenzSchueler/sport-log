import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'platform_credential.g.dart';

@JsonSerializable()
class PlatformCredential implements DbObject {
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

  Map<String, dynamic> toJson() => _$PlatformCredentialToJson(this);

  @override
  bool isValid() {
    return validate(!deleted, 'PlatformCredential: deleted == true') &&
        validate(
            username.isNotEmpty, 'PlatformCredential: username is empty') &&
        validate(password.isNotEmpty, 'PlatformCredential: password is empty');
  }
}

class DbPlatformCredentialSerializer
    implements DbSerializer<PlatformCredential> {
  @override
  PlatformCredential fromDbRecord(DbRecord r) {
    return PlatformCredential(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      platformId: Int64(r[Keys.platformId]! as int),
      username: r[Keys.username]! as String,
      password: r[Keys.password]! as String,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(PlatformCredential o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.platformId: o.platformId.toInt(),
      Keys.username: o.username,
      Keys.password: o.password,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
