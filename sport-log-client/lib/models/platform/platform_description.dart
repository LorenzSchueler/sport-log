import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/clone_extensions.dart';

part 'platform_description.g.dart';

@JsonSerializable()
class PlatformDescription extends CompoundEntity {
  PlatformDescription({
    required this.platform,
    required this.platformCredential,
    required this.actionProviders,
  });

  factory PlatformDescription.fromJson(Map<String, dynamic> json) =>
      _$PlatformDescriptionFromJson(json);

  Platform platform;
  PlatformCredential? platformCredential;
  List<ActionProvider> actionProviders;

  @override
  Map<String, dynamic> toJson() => _$PlatformDescriptionToJson(this);

  @override
  PlatformDescription clone() => PlatformDescription(
    platform: platform.clone(),
    platformCredential: platformCredential?.clone(),
    actionProviders: actionProviders.clone(),
  );

  @override
  bool isValidBeforeSanitation() {
    return platform.isValidBeforeSanitation() &&
        (platformCredential?.isValidBeforeSanitation() ?? true) &&
        actionProviders.every((a) => a.isValidBeforeSanitation()) &&
        validate(
          !platform.credential || platformCredential != null,
          'PlatformDescription: credentials required but null',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        platform.isValid() &&
        (platformCredential?.isValid() ?? true) &&
        actionProviders.every((a) => a.isValid());
  }

  @override
  void sanitize() {
    platform.sanitize();
    platformCredential?.sanitize();
  }
}
