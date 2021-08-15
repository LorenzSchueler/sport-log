
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/json_serialization.dart';

part 'action_event.g.dart';

@JsonSerializable()
class ActionEvent {
  ActionEvent({
    required this.id,
    required this.userId,
    required this.actionId,
    required this.datetime,
    required this.enabled,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @IdConverter() Int64 actionId;
  DateTime datetime;
  bool enabled;
  bool deleted;

  factory ActionEvent.fromJson(Map<String, dynamic> json) => _$ActionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ActionEventToJson(this);
}