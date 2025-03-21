import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/clone_extensions.dart';

part 'action_provider_description.g.dart';

@JsonSerializable()
class ActionProviderDescription extends CompoundEntity {
  ActionProviderDescription({
    required this.actionProvider,
    required this.actions,
    required this.actionRules,
    required this.actionEvents,
  });

  factory ActionProviderDescription.fromJson(Map<String, dynamic> json) =>
      _$ActionProviderDescriptionFromJson(json);

  ActionProvider actionProvider;
  List<Action> actions;
  List<ActionRule> actionRules;
  List<ActionEvent> actionEvents;

  @override
  Map<String, dynamic> toJson() => _$ActionProviderDescriptionToJson(this);

  @override
  ActionProviderDescription clone() => ActionProviderDescription(
    actionProvider: actionProvider.clone(),
    actions: actions.clone(),
    actionRules: actionRules.clone(),
    actionEvents: actionEvents.clone(),
  );

  @override
  bool isValidBeforeSanitation() {
    return actionProvider.isValidBeforeSanitation() &&
        actions.every((a) => a.isValidBeforeSanitation()) &&
        actionRules.every((a) => a.isValidBeforeSanitation()) &&
        actionEvents.every((a) => a.isValidBeforeSanitation());
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
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
