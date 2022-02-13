part of '../api.dart';

class ActionProviderApi extends Api<ActionProvider> {
  @override
  ActionProvider _fromJson(Map<String, dynamic> json) =>
      ActionProvider.fromJson(json);

  @override
  String get _singularRoute => version + '/action_provider';

  @override
  ApiResult<void> postSingle(ActionProvider object) =>
      throw UnimplementedError();

  @override
  ApiResult<void> postMultiple(List<ActionProvider> objects) =>
      throw UnimplementedError();

  @override
  ApiResult<void> putSingle(ActionProvider object) =>
      throw UnimplementedError();

  @override
  ApiResult<void> putMultiple(List<ActionProvider> objects) =>
      throw UnimplementedError();
}

class ActionApi extends Api<Action> {
  @override
  Action _fromJson(Map<String, dynamic> json) => Action.fromJson(json);

  @override
  String get _singularRoute => version + '/action';

  @override
  ApiResult<void> postSingle(Action object) => throw UnimplementedError();

  @override
  ApiResult<void> postMultiple(List<Action> objects) =>
      throw UnimplementedError();

  @override
  ApiResult<void> putSingle(Action object) => throw UnimplementedError();

  @override
  ApiResult<void> putMultiple(List<Action> objects) =>
      throw UnimplementedError();
}

class ActionRuleApi extends Api<ActionRule> {
  @override
  ActionRule _fromJson(Map<String, dynamic> json) => ActionRule.fromJson(json);

  @override
  String get _singularRoute => version + '/action_rule';
}

class ActionEventApi extends Api<ActionEvent> {
  @override
  ActionEvent _fromJson(Map<String, dynamic> json) =>
      ActionEvent.fromJson(json);

  @override
  String get _singularRoute => version + '/action_event';
}
