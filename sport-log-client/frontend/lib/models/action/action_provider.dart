
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';

part 'action_provider.g.dart';

@JsonSerializable()
class ActionProvider implements DbObject {
  ActionProvider({
    required this.id,
    required this.name,
    required this.password,
    required this.platformId,
    required this.description,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  String name;
  String password;
  @IdConverter() Int64 platformId;
  String? description;
  @override
  bool deleted;

  factory ActionProvider.fromJson(Map<String, dynamic> json) => _$ActionProviderFromJson(json);
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);

  @override
  bool isValid() {
    return name.isNotEmpty && password.isNotEmpty && !deleted;
  }
}