
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/id_serialization.dart';

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
    required this.deleted,
  });

  @IdConverter() Int64 id;
  String name;
  @IdConverter() Int64 actionProviderId;
  String? description;
  int createBefore;
  int deleteAfter;
  bool deleted;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
  Map<String, dynamic> toJson() => _$ActionToJson(this);
}
