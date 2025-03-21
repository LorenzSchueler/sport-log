import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/result.dart';
import 'package:sport_log/models/action/all.dart';
import 'package:sport_log/models/epoch/epoch_result.dart';

class ActionProviderApi extends Api<ActionProvider> {
  factory ActionProviderApi() => _instance;

  ActionProviderApi._();

  static final _instance = ActionProviderApi._();

  @override
  ActionProvider fromJson(Map<String, dynamic> json) =>
      ActionProvider.fromJson(json);

  @override
  final route = '/action_provider';

  @override
  Future<ApiResult<EpochResult?>> postSingle(ActionProvider object) async =>
      Ok(null);

  @override
  Future<ApiResult<EpochResult?>> postMultiple(
    List<ActionProvider> objects,
  ) async => Ok(null);

  @override
  Future<ApiResult<EpochResult?>> putSingle(ActionProvider object) async =>
      Ok(null);

  @override
  Future<ApiResult<EpochResult?>> putMultiple(
    List<ActionProvider> objects,
  ) async => Ok(null);
}

class ActionApi extends Api<Action> {
  factory ActionApi() => _instance;

  ActionApi._();

  static final _instance = ActionApi._();

  @override
  Action fromJson(Map<String, dynamic> json) => Action.fromJson(json);

  @override
  final route = '/action';

  @override
  Future<ApiResult<EpochResult?>> postSingle(Action object) async => Ok(null);

  @override
  Future<ApiResult<EpochResult?>> postMultiple(List<Action> objects) async =>
      Ok(null);

  @override
  Future<ApiResult<EpochResult?>> putSingle(Action object) async => Ok(null);

  @override
  Future<ApiResult<EpochResult?>> putMultiple(List<Action> objects) async =>
      Ok(null);
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
