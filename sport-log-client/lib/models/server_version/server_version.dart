import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/config.dart';

part 'server_version.g.dart';

@JsonSerializable()
class _ServerVersionString {
  _ServerVersionString({
    required this.min,
    required this.max,
  });

  factory _ServerVersionString.fromJson(Map<String, dynamic> json) =>
      _$ServerVersionStringFromJson(json);

  String min;
  String max;
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

  bool comatibleWithClientApiVersion() {
    return Config.apiVersion.compareTo(min) >= 0 &&
        Config.apiVersion.compareTo(max) <= 0;
  }
}

class Version extends Comparable<Version> {
  Version(this.major, this.minor, [this.patch]);

  factory Version.fromString(String version) {
    final parts = version.split("-")[0].split(".");
    return Version(
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length == 3 ? int.parse(parts[2]) : null,
    );
  }

  final int major;
  final int minor;
  final int? patch;

  @override
  String toString() => patch != null ? "$major.$minor.$patch" : "$major.$minor";

  @override
  int compareTo(Version other) {
    return major != other.major ? major - other.major : minor - other.minor;
  }
}
