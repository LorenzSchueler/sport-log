
import 'package:json_annotation/json_annotation.dart';

part 'platform.g.dart';

@JsonSerializable()
class Platform {
  Platform({
    required this.id,
    required this.name,
  });

  int id;
  String name;

  factory Platform.fromJson(Map<String, dynamic> json) => _$PlatformFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformToJson(this);
}

@JsonSerializable()
class NewPlatform {
  NewPlatform({
    required this.name,
  });

  String name;

  factory NewPlatform.fromJson(Map<String, dynamic> json) => _$NewPlatformFromJson(json);
  Map<String, dynamic> toJson() => _$NewPlatformToJson(this);
}
