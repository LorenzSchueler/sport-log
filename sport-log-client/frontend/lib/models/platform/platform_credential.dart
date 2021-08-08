
import 'package:json_annotation/json_annotation.dart';

part 'platform_credential.g.dart';

@JsonSerializable()
class PlatformCredential {
  PlatformCredential({
    required this.id,
    required this.userId,
    required this.platformId,
    required this.username,
    required this.password,
  });

  int id;
  int userId;
  int platformId;
  String username;
  String password;

  factory PlatformCredential.fromJson(Map<String, dynamic> json) => _$PlatformCredentialFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformCredentialToJson(this);
}

@JsonSerializable()
class NewPlatformCredential {
  NewPlatformCredential({
    required this.userId,
    required this.platformId,
    required this.username,
    required this.password,
  });

  int userId;
  int platformId;
  String username;
  String password;

  factory NewPlatformCredential.fromJson(Map<String, dynamic> json) => _$NewPlatformCredentialFromJson(json);
  Map<String, dynamic> toJson() => _$NewPlatformCredentialToJson(this);
}
