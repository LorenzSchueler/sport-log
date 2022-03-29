import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/all.dart';

part 'platform_description.g.dart';

@JsonSerializable()
class PlatformDescription extends CompoundEntity {
  PlatformDescription(
      {required this.platform, required this.platformCredential});

  Platform platform;
  PlatformCredential? platformCredential;

  factory PlatformDescription.fromJson(Map<String, dynamic> json) =>
      _$PlatformDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlatformDescriptionToJson(this);

  @override
  PlatformDescription clone() => PlatformDescription(
        platform: platform.clone(),
        platformCredential: platformCredential?.clone(),
      );

  @override
  bool isValidBeforeSanitazion() {
    return platform.isValidBeforeSanitazion() &&
        (platformCredential == null ||
            platformCredential!.isValidBeforeSanitazion()) &&
        validate(
          !platform.credential || platformCredential != null,
          'PlatformDesciption: credentials required but null',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        platform.isValid() &&
        (platformCredential == null || platformCredential!.isValid());
  }

  @override
  void sanitize() {
    platform.sanitize();
    platformCredential?.sanitize();
  }
}
