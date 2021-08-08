
import 'package:json_annotation/json_annotation.dart';

part 'action.g.dart';

@JsonSerializable()
class Action {
  Action({
    required this.id,
    required this.name,
    required this.actionProviderId,
    required this.description,
    required this.createBefore,
    required this.deleteAfter,
  });

  int id;
  String name;
  int actionProviderId;
  String? description;
  int createBefore;
  int deleteAfter;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
  Map<String, dynamic> toJson() => _$ActionToJson(this);
}
