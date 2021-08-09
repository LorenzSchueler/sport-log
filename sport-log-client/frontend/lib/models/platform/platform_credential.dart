
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/id_serialization.dart';

part 'platform_credential.g.dart';

@JsonSerializable()
class PlatformCredential {
  PlatformCredential({
    required this.id,
    required this.userId,
    required this.platformId,
    required this.username,
    required this.password,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 platformId;
  String username;
  String password;
  bool deleted;

  factory PlatformCredential.fromJson(Map<String, dynamic> json) => _$PlatformCredentialFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformCredentialToJson(this);
}