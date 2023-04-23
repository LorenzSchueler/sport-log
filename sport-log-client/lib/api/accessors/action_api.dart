import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/action/all.dart';

class ActionProviderApi extends Api<ActionProvider> {
  @override
  ActionProvider fromJson(Map<String, dynamic> json) =>
      ActionProvider.fromJson(json);

  @override
  final route = '/action_provider';
}

class ActionApi extends Api<Action> {
  @override
  Action fromJson(Map<String, dynamic> json) => Action.fromJson(json);

  @override
  final route = '/action';
}

class ActionRuleApi extends Api<ActionRule> {
  @override
  ActionRule fromJson(Map<String, dynamic> json) => ActionRule.fromJson(json);

  @override
  final route = '/action_rule';
}

class ActionEventApi extends Api<ActionEvent> {
  @override
  ActionEvent fromJson(Map<String, dynamic> json) => ActionEvent.fromJson(json);

  @override
  final route = '/action_event';
}
