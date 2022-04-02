import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/all.dart';

part 'action_provider_description.g.dart';

@JsonSerializable()
class ActionProviderDescription extends CompoundEntity {
  ActionProviderDescription({
    required this.actionProvider,
    required this.actions,
    required this.actionRules,
    required this.actionEvents,
  });

  ActionProvider actionProvider;
  List<Action> actions;
  List<ActionRule> actionRules;
  List<ActionEvent> actionEvents;

  factory ActionProviderDescription.fromJson(Map<String, dynamic> json) =>
      _$ActionProviderDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActionProviderDescriptionToJson(this);

  @override
  ActionProviderDescription clone() => ActionProviderDescription(
        actionProvider: actionProvider.clone(),
        actions: actions.map((a) => a.clone()).toList(),
        actionRules: actionRules.map((a) => a.clone()).toList(),
        actionEvents: actionEvents.map((a) => a.clone()).toList(),
      );

  @override
  bool isValidBeforeSanitazion() {
    return actionProvider.isValidBeforeSanitazion() &&
        actions.every((a) => a.isValidBeforeSanitazion()) &&
        actionRules.every((a) => a.isValidBeforeSanitazion()) &&
        actionEvents.every((a) => a.isValidBeforeSanitazion());
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        actionProvider.isValid() &&
        actions.every((a) => a.isValid()) &&
        actionRules.every((a) => a.isValid()) &&
        actionEvents.every((a) => a.isValid());
  }

  @override
  void sanitize() {
    actionProvider.sanitize();
    for (final action in actions) {
      action.sanitize();
    }
    for (final actionRule in actionRules) {
      actionRule.sanitize();
    }
    for (final actionEvent in actionEvents) {
      actionEvent.sanitize();
    }
  }
}
