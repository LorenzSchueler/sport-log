
import 'package:json_annotation/json_annotation.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';

part 'platform.g.dart';

@JsonSerializable()
class Platform implements DbObject {
  Platform({
    required this.id,
    required this.name,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  String name;
  @override
  bool deleted;

  factory Platform.fromJson(Map<String, dynamic> json) => _$PlatformFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformToJson(this);

  @override
  bool isValid() {
    return name.isNotEmpty && !deleted;
  }
}