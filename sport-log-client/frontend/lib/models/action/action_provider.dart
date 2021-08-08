
import 'package:json_annotation/json_annotation.dart';

part 'action_provider.g.dart';

@JsonSerializable()
class ActionProvider {
  ActionProvider({
    required this.id,
    required this.name,
    required this.password,
    required this.platformId,
    required this.description,
    required this.deleted,
  });

  int id;
  String name;
  String password;
  int platformId;
  String? description;
  bool deleted;

  factory ActionProvider.fromMap(Map<String, dynamic> json) => _$ActionProviderFromJson(json);
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);
}