part of '../api.dart';

extension ActionRoutes on Api {
  // Action Providers

  ApiResult<List<ActionProvider>> getActionProviders() async {
    return _getMultiple(BackendRoutes.actionProvider,
        fromJson: (json) => ActionProvider.fromJson(json));
  }

  ApiResult<ActionProvider> getActionProvider(Int64 id) async {
    return _getSingle(BackendRoutes.actionProvider + '/$id',
        fromJson: (json) => ActionProvider.fromJson(json));
  }

  // Actions

  ApiResult<List<Action>> getActions() async {
    return _getMultiple(BackendRoutes.action,
        fromJson: (json) => Action.fromJson(json));
  }

  ApiResult<Action> getAction(Int64 id) async {
    return _getSingle(BackendRoutes.action + '/$id',
        fromJson: (json) => Action.fromJson(json));
  }

  // Action Rules

  ApiResult<void> createActionRule(ActionRule ar) async {
    return _post(BackendRoutes.actionRule, ar);
  }

  ApiResult<void> createActionRules(List<ActionRule> ars) async {
    return _post(BackendRoutes.actionRule, ars);
  }

  ApiResult<List<ActionRule>> getActionRules() async {
    return _getMultiple(BackendRoutes.actionRule,
        fromJson: (json) => ActionRule.fromJson(json));
  }

  ApiResult<ActionRule> getActionRule(Int64 id) async {
    return _getSingle(BackendRoutes.actionRule + '/$id',
        fromJson: (json) => ActionRule.fromJson(json));
  }

  ApiResult<List<ActionRule>> getActionRulesByActionProvider(Int64 id) async {
    return _getMultiple(BackendRoutes.actionRuleByActionProvider(id),
        fromJson: (json) => ActionRule.fromJson(json));
  }

  ApiResult<void> updateActionRule(ActionRule ar) async {
    return _put(BackendRoutes.actionRule, ar);
  }

  ApiResult<void> updateActionRules(List<ActionRule> ars) async {
    return _put(BackendRoutes.actionRule, ars);
  }

  // Action Events

  ApiResult<void> createActionEvent(ActionEvent ae) async {
    return _post(BackendRoutes.actionEvent, ae);
  }

  ApiResult<void> createActionEvents(List<ActionEvent> aes) async {
    return _post(BackendRoutes.actionEvent, aes);
  }

  ApiResult<List<ActionEvent>> getActionEvents() async {
    return _getMultiple(BackendRoutes.actionEvent,
        fromJson: (json) => ActionEvent.fromJson(json));
  }

  ApiResult<ActionEvent> getActionEvent(Int64 id) async {
    return _getSingle(BackendRoutes.actionEvent + '/$id',
        fromJson: (json) => ActionEvent.fromJson(json));
  }

  ApiResult<List<ActionEvent>> getActionEventsByActionProvider(Int64 id) async {
    return _getMultiple(BackendRoutes.actionEventByActionProvider(id),
        fromJson: (json) => ActionEvent.fromJson(json));
  }

  ApiResult<void> updateActionEvent(ActionEvent ae) async {
    return _put(BackendRoutes.actionEvent, ae);
  }

  ApiResult<void> updateActionEvents(List<ActionEvent> aes) async {
    return _put(BackendRoutes.actionEvent, aes);
  }
}
