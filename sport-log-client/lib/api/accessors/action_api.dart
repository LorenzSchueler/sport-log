import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/action/all.dart';

class ActionProviderApi extends Api<ActionProvider> {
  factory ActionProviderApi() => _instance;

  ActionProviderApi._();

  static final _instance = ActionProviderApi._();

  @override
  ActionProvider fromJson(Map<String, dynamic> json) =>
      ActionProvider.fromJson(json);

  @override
  final route = '/action_provider';
}

class ActionApi extends Api<Action> {
  factory ActionApi() => _instance;

  ActionApi._();

  static final _instance = ActionApi._();

  @override
  Action fromJson(Map<String, dynamic> json) => Action.fromJson(json);

  @override
  final route = '/action';
}

class ActionRuleApi extends Api<ActionRule> {
  factory ActionRuleApi() => _instance;

  ActionRuleApi._();

  static final _instance = ActionRuleApi._();

  @override
  ActionRule fromJson(Map<String, dynamic> json) => ActionRule.fromJson(json);

  @override
  final route = '/action_rule';
}

class ActionEventApi extends Api<ActionEvent> {
  factory ActionEventApi() => _instance;

  ActionEventApi._();

  static final _instance = ActionEventApi._();

  @override
  ActionEvent fromJson(Map<String, dynamic> json) => ActionEvent.fromJson(json);

  @override
  final route = '/action_event';
}
