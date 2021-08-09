
import 'package:json_annotation/json_annotation.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/helpers/id_serialization.dart';

part 'platform.g.dart';

@JsonSerializable()
class Platform {
  Platform({
    required this.id,
    required this.name,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  String name;
  bool deleted;

  factory Platform.fromJson(Map<String, dynamic> json) => _$PlatformFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformToJson(this);
}