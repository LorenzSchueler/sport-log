part of '../api.dart';

class ActionProviderApi extends ApiAccessor<ActionProvider> {
  @override
  ActionProvider fromJson(Map<String, dynamic> json) =>
      ActionProvider.fromJson(json);

  @override
  String get singularRoute => version + '/action_provider';

  @override
  Map<String, dynamic> toJson(ActionProvider object) => object.toJson();

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

class ActionApi extends ApiAccessor<Action> {
  @override
  Action fromJson(Map<String, dynamic> json) => Action.fromJson(json);

  @override
  String get singularRoute => version + '/action';

  @override
  Map<String, dynamic> toJson(Action object) => object.toJson();

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

class ActionRuleApi extends ApiAccessor<ActionRule> {
  @override
  ActionRule fromJson(Map<String, dynamic> json) => ActionRule.fromJson(json);

  @override
  String get singularRoute => version + '/action_rule';

  @override
  Map<String, dynamic> toJson(ActionRule object) => object.toJson();
}

class ActionEventApi extends ApiAccessor<ActionEvent> {
  @override
  ActionEvent fromJson(Map<String, dynamic> json) => ActionEvent.fromJson(json);

  @override
  String get singularRoute => version + '/action_event';

  @override
  Map<String, dynamic> toJson(ActionEvent object) => object.toJson();
}
