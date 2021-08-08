
import 'package:json_annotation/json_annotation.dart';

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

  int id;
  int userId;
  int actionId;
  DateTime datetime;
  bool enabled;
  bool deleted;

  factory ActionEvent.fromJson(Map<String, dynamic> json) => _$ActionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ActionEventToJson(this);
}