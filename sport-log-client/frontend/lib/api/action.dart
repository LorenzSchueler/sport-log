
part of 'api.dart';

extension ActionRoutes on Api {

  // Action Providers

  ApiResult<List<ActionProvider>> getActionProviders() async {
    return _get(BackendRoutes.actionProvider);
  }

  // Actions

  ApiResult<List<Action>> getActions() async {
    return _get(BackendRoutes.action);
  }

  // Action Rules

  ApiResult<void> createActionRule(ActionRule ar) async {
    return _post(BackendRoutes.actionRule, ar);
  }

  ApiResult<void> createActionRules(List<ActionRule> ars) async {
    return _post(BackendRoutes.actionRule, ars);
  }

  ApiResult<List<ActionRule>> getActionRules() async {
    return _get(BackendRoutes.actionRule);
  }

  ApiResult<List<ActionRule>> getActionRulesByActionProvider(Int64 id) async {
    return _get(BackendRoutes.actionRuleByActionProvider(id));
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
    return _get(BackendRoutes.actionEvent);
  }

  ApiResult<List<ActionEvent>> getActionEventsByActionProvider(Int64 id) async {
    return _get(BackendRoutes.actionEventByActionProvider(id));
  }

  ApiResult<void> updateActionEvent(ActionEvent ae) async {
    return _put(BackendRoutes.actionEvent, ae);
  }

  ApiResult<void> updateActionEvents(List<ActionEvent> aes) async {
    return _put(BackendRoutes.actionEvent, aes);
  }
}