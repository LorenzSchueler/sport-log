import 'package:json_annotation/json_annotation.dart';

part 'server_version.g.dart';

@JsonSerializable()
class _ServerVersionString {
  _ServerVersionString({
    required this.min,
    required this.max,
  });

  String min;
  String max;

  factory _ServerVersionString.fromJson(Map<String, dynamic> json) =>
      _$ServerVersionStringFromJson(json);
}

class ServerVersion extends JsonSerializable {
  ServerVersion._(this.min, this.max);

  factory ServerVersion.fromJson(Map<String, dynamic> json) {
    final serverVersionString = _ServerVersionString.fromJson(json);
    return ServerVersion._(
      Version.fromString(serverVersionString.min),
      Version.fromString(serverVersionString.max),
    );
  }

  Version min;
  Version max;

  @override
  String toString() => "$min - $max";
}

class Version {
  Version(this.major, this.minor);

  factory Version.fromString(String version) {
    final parts = version.split(".");
    return Version(int.parse(parts[0]), int.parse(parts[1]));
  }

  int major;
  int minor;

  @override
  String toString() => "$major.$minor";
}
