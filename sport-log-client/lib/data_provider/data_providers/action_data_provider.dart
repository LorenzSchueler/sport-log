import 'package:sport_log/api/accessors/action_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/action_tables.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/action/all.dart';
import 'package:sport_log/models/epoch/epoch_map.dart';
import 'package:sport_log/models/epoch/epoch_result.dart';
import 'package:sport_log/models/platform/platform.dart';

class ActionProviderDataProvider extends EntityDataProvider<ActionProvider> {
  factory ActionProviderDataProvider() => _instance;

  ActionProviderDataProvider._();

  static final _instance = ActionProviderDataProvider._();

  @override
  final Api<ActionProvider> api = ActionProviderApi();

  @override
  final ActionProviderTable table = ActionProviderTable();

  @override
  List<ActionProvider> getFromAccountData(AccountData accountData) =>
      accountData.actionProviders;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.actionProvider = epochResult.epoch;
  }

  Future<List<ActionProvider>> getByPlatform(Platform platform) =>
      table.getByPlatform(platform);
}

class ActionDataProvider extends EntityDataProvider<Action> {
  factory ActionDataProvider() => _instance;

  ActionDataProvider._();

  static final _instance = ActionDataProvider._();

  @override
  final Api<Action> api = ActionApi();

  @override
  final ActionTable table = ActionTable();

  @override
  List<Action> getFromAccountData(AccountData accountData) =>
      accountData.actions;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.action = epochResult.epoch;
  }

  Future<List<Action>> getByActionProvider(ActionProvider actionProvider) =>
      table.getByActionProvider(actionProvider);
}

class ActionRuleDataProvider extends EntityDataProvider<ActionRule> {
  factory ActionRuleDataProvider() => _instance;

  ActionRuleDataProvider._();

  static final _instance = ActionRuleDataProvider._();

  @override
  final Api<ActionRule> api = ActionRuleApi();

  @override
  final ActionRuleTable table = ActionRuleTable();

  @override
  List<ActionRule> getFromAccountData(AccountData accountData) =>
      accountData.actionRules;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.actionRule = epochResult.epoch;
  }

  Future<List<ActionRule>> getByActionProvider(ActionProvider actionProvider) =>
      table.getByActionProvider(actionProvider);
}

class ActionEventDataProvider extends EntityDataProvider<ActionEvent> {
  factory ActionEventDataProvider() => _instance;

  ActionEventDataProvider._();

  static final _instance = ActionEventDataProvider._();

  @override
  final Api<ActionEvent> api = ActionEventApi();

  @override
  final ActionEventTable table = ActionEventTable();

  @override
  List<ActionEvent> getFromAccountData(AccountData accountData) =>
      accountData.actionEvents;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.actionEvent = epochResult.epoch;
  }

  Future<List<ActionEvent>> getByActionProvider(
    ActionProvider actionProvider,
  ) => table.getByActionProvider(actionProvider);
}

class ActionProviderDescriptionDataProvider
    extends DataProvider<ActionProviderDescription> {
  factory ActionProviderDescriptionDataProvider() {
    if (_instance == null) {
      _instance = ActionProviderDescriptionDataProvider._();
      _instance!._actionProviderDataProvider.addListener(
        _instance!.notifyListeners,
      );
      _instance!._actionDataProvider.addListener(_instance!.notifyListeners);
      _instance!._actionRuleDataProvider.addListener(
        _instance!.notifyListeners,
      );
      _instance!._actionEventDataProvider.addListener(
        _instance!.notifyListeners,
      );
    }
    return _instance!;
  }

  ActionProviderDescriptionDataProvider._();

  static ActionProviderDescriptionDataProvider? _instance;

  final _actionProviderDataProvider = ActionProviderDataProvider();
  final _actionDataProvider = ActionDataProvider();
  final _actionRuleDataProvider = ActionRuleDataProvider();
  final _actionEventDataProvider = ActionEventDataProvider();

  @override
  Future<DbResult> createSingle(ActionProviderDescription object) async {
    object.sanitize();
    assert(object.isValid());
    final result = await _actionRuleDataProvider.createMultiple(
      object.actionRules,
      notify: false,
    );
    if (result.isErr) {
      return result;
    }
    return _actionEventDataProvider.createMultiple(object.actionEvents);
  }

  @override
  Future<DbResult> updateSingle(ActionProviderDescription object) async {
    throw UnimplementedError();
  }

  @override
  Future<DbResult> deleteSingle(ActionProviderDescription object) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ActionProviderDescription>> getNonDeleted() {
    throw UnimplementedError();
  }

  Future<ActionProviderDescription?> getByActionProvider(
    ActionProvider actionProvider,
  ) async {
    final loadedActionProvider = await _actionProviderDataProvider.getById(
      actionProvider.id,
    );
    if (loadedActionProvider == null) {
      return null;
    }
    return ActionProviderDescription(
      actionProvider: loadedActionProvider,
      actions: await _actionDataProvider.getByActionProvider(actionProvider),
      actionRules: await _actionRuleDataProvider.getByActionProvider(
        actionProvider,
      ),
      actionEvents: await _actionEventDataProvider.getByActionProvider(
        actionProvider,
      ),
    );
  }
}
