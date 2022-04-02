import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/action_tables.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/action/all.dart';
import 'package:sport_log/models/platform/platform.dart';

class ActionProviderDataProvider extends EntityDataProvider<ActionProvider> {
  static final _instance = ActionProviderDataProvider._();
  ActionProviderDataProvider._();
  factory ActionProviderDataProvider() => _instance;

  @override
  final Api<ActionProvider> api = Api.actionProviders;

  @override
  final ActionProviderTable db = AppDatabase.actionProviders;

  @override
  List<ActionProvider> getFromAccountData(AccountData accountData) =>
      accountData.actionProviders;

  Future<List<ActionProvider>> getByPlatform(Platform platfrom) =>
      db.getByPlatform(platfrom);
}

class ActionDataProvider extends EntityDataProvider<Action> {
  static final _instance = ActionDataProvider._();
  ActionDataProvider._();
  factory ActionDataProvider() => _instance;

  @override
  final Api<Action> api = Api.actions;

  @override
  final ActionTable db = AppDatabase.actions;

  @override
  List<Action> getFromAccountData(AccountData accountData) =>
      accountData.actions;

  Future<List<Action>> getByActionProvider(ActionProvider actionProvider) =>
      db.getByActionProvider(actionProvider);
}

class ActionRuleDataProvider extends EntityDataProvider<ActionRule> {
  static final _instance = ActionRuleDataProvider._();
  ActionRuleDataProvider._();
  factory ActionRuleDataProvider() => _instance;

  @override
  final Api<ActionRule> api = Api.actionRules;

  @override
  final ActionRuleTable db = AppDatabase.actionRules;

  @override
  List<ActionRule> getFromAccountData(AccountData accountData) =>
      accountData.actionRules;

  Future<List<ActionRule>> getByActionProvider(ActionProvider actionProvider) =>
      db.getByActionProvider(actionProvider);
}

class ActionEventDataProvider extends EntityDataProvider<ActionEvent> {
  static final _instance = ActionEventDataProvider._();
  ActionEventDataProvider._();
  factory ActionEventDataProvider() => _instance;

  @override
  final Api<ActionEvent> api = Api.actionEvents;

  @override
  final ActionEventTable db = AppDatabase.actionEvents;

  @override
  List<ActionEvent> getFromAccountData(AccountData accountData) =>
      accountData.actionEvents;

  Future<List<ActionEvent>> getByActionProvider(
    ActionProvider actionProvider,
  ) =>
      db.getByActionProvider(actionProvider);
}

class ActionProviderDescriptionDataProvider
    extends DataProvider<ActionProviderDescription> {
  final _actionProviderDataProvider = ActionProviderDataProvider();
  final _actionDataProvider = ActionDataProvider();
  final _actionRuleDataProvider = ActionRuleDataProvider();
  final _actionEventDataProvider = ActionEventDataProvider();

  ActionProviderDescriptionDataProvider._();
  static ActionProviderDescriptionDataProvider? _instance;
  factory ActionProviderDescriptionDataProvider() {
    if (_instance == null) {
      _instance = ActionProviderDescriptionDataProvider._();
      _instance!._actionProviderDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._actionDataProvider.addListener(_instance!.notifyListeners);
      _instance!._actionRuleDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._actionEventDataProvider
          .addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<DbResult> createSingle(ActionProviderDescription object) async {
    object.sanitize();
    assert(object.isValid());
    final result =
        await _actionRuleDataProvider.createMultiple(object.actionRules);
    if (result.isFailure()) {
      return result;
    }
    return await _actionEventDataProvider.createMultiple(object.actionEvents);
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

  @override
  Future<bool> pushUpdatedToServer() async {
    if (!await _actionRuleDataProvider.pushUpdatedToServer()) {
      return false;
    }
    return await _actionEventDataProvider.pushUpdatedToServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    if (!await _actionRuleDataProvider.pushCreatedToServer()) {
      return false;
    }
    return await _actionEventDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pullFromServer() async {
    if (!await _actionRuleDataProvider.pullFromServer()) {
      return false;
    }
    return await _actionEventDataProvider.pullFromServer();
  }

  Future<ActionProviderDescription> getByActionProvider(
    ActionProvider actionProvider,
  ) async {
    return ActionProviderDescription(
      actionProvider: actionProvider,
      actions: await _actionDataProvider.getByActionProvider(actionProvider),
      actionRules:
          await _actionRuleDataProvider.getByActionProvider(actionProvider),
      actionEvents:
          await _actionEventDataProvider.getByActionProvider(actionProvider),
    );
  }
}
