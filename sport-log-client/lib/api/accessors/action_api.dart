part of '../api.dart';

class ActionProviderApi extends Api<ActionProvider> {
  @override
  ActionProvider _fromJson(Map<String, dynamic> json) =>
      ActionProvider.fromJson(json);

  @override
  String get _route => '/action_provider';
}

class ActionApi extends Api<Action> {
  @override
  Action _fromJson(Map<String, dynamic> json) => Action.fromJson(json);

  @override
  String get _route => '/action';
}

class ActionRuleApi extends Api<ActionRule> {
  @override
  ActionRule _fromJson(Map<String, dynamic> json) => ActionRule.fromJson(json);

  @override
  String get _route => '/action_rule';
}

class ActionEventApi extends Api<ActionEvent> {
  @override
  ActionEvent _fromJson(Map<String, dynamic> json) =>
      ActionEvent.fromJson(json);

  @override
  String get _route => '/action_event';
}
