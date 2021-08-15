
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/json_serialization.dart';

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

  @IdConverter() Int64 id;
  String name;
  String password;
  @IdConverter() Int64 platformId;
  String? description;
  bool deleted;

  factory ActionProvider.fromMap(Map<String, dynamic> json) => _$ActionProviderFromJson(json);
  Map<String, dynamic> toJson() => _$ActionProviderToJson(this);
}