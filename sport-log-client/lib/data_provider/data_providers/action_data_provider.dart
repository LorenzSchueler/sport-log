import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/action/all.dart';

class ActionProviderDataProvider extends EntityDataProvider<ActionProvider> {
  static final _instance = ActionProviderDataProvider._();
  ActionProviderDataProvider._();
  factory ActionProviderDataProvider() => _instance;

  @override
  final Api<ActionProvider> api = Api.actionProviders;

  @override
  final TableAccessor<ActionProvider> db = AppDatabase.actionProviders;

  @override
  List<ActionProvider> getFromAccountData(AccountData accountData) =>
      accountData.actionProviders;
}

class ActionDataProvider extends EntityDataProvider<Action> {
  static final _instance = ActionDataProvider._();
  ActionDataProvider._();
  factory ActionDataProvider() => _instance;

  @override
  final Api<Action> api = Api.actions;

  @override
  final TableAccessor<Action> db = AppDatabase.actions;

  @override
  List<Action> getFromAccountData(AccountData accountData) =>
      accountData.actions;
}

class ActionRuleDataProvider extends EntityDataProvider<ActionRule> {
  static final _instance = ActionRuleDataProvider._();
  ActionRuleDataProvider._();
  factory ActionRuleDataProvider() => _instance;

  @override
  final Api<ActionRule> api = Api.actionRules;

  @override
  final TableAccessor<ActionRule> db = AppDatabase.actionRules;

  @override
  List<ActionRule> getFromAccountData(AccountData accountData) =>
      accountData.actionRules;
}

class ActionEventDataProvider extends EntityDataProvider<ActionEvent> {
  static final _instance = ActionEventDataProvider._();
  ActionEventDataProvider._();
  factory ActionEventDataProvider() => _instance;

  @override
  final Api<ActionEvent> api = Api.actionEvents;

  @override
  final TableAccessor<ActionEvent> db = AppDatabase.actionEvents;

  @override
  List<ActionEvent> getFromAccountData(AccountData accountData) =>
      accountData.actionEvents;
}
