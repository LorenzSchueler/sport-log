import 'package:json_annotation/json_annotation.dart';

part 'server_version.g.dart';

@JsonSerializable()
class ServerVersion extends JsonSerializable {
  ServerVersion({
    required this.min,
    required this.max,
  });

  String min;
  String max;

  factory ServerVersion.fromJson(Map<String, dynamic> json) =>
      _$ServerVersionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ServerVersionToJson(this);

  @override
  String toString() => toJson().toString();
}
