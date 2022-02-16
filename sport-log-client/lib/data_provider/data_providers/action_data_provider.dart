import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/action/all.dart';

class ActionProviderDataProvider extends EntityDataProvider<ActionProvider> {
  static final instance = ActionProviderDataProvider._();
  ActionProviderDataProvider._();

  @override
  final Api<ActionProvider> api = Api.actionProviders;

  @override
  final DbAccessor<ActionProvider> db = AppDatabase.actionProviders;

  @override
  List<ActionProvider> getFromAccountData(AccountData accountData) =>
      accountData.actionProviders;
}

class ActionDataProvider extends EntityDataProvider<Action> {
  static final instance = ActionDataProvider._();
  ActionDataProvider._();

  @override
  final Api<Action> api = Api.actions;

  @override
  final DbAccessor<Action> db = AppDatabase.actions;

  @override
  List<Action> getFromAccountData(AccountData accountData) =>
      accountData.actions;
}

class ActionRuleDataProvider extends EntityDataProvider<ActionRule> {
  static final instance = ActionRuleDataProvider._();
  ActionRuleDataProvider._();

  @override
  final Api<ActionRule> api = Api.actionRules;

  @override
  final DbAccessor<ActionRule> db = AppDatabase.actionRules;

  @override
  List<ActionRule> getFromAccountData(AccountData accountData) =>
      accountData.actionRules;
}

class ActionEventDataProvider extends EntityDataProvider<ActionEvent> {
  static final instance = ActionEventDataProvider._();
  ActionEventDataProvider._();

  @override
  final Api<ActionEvent> api = Api.actionEvents;

  @override
  final DbAccessor<ActionEvent> db = AppDatabase.actionEvents;

  @override
  List<ActionEvent> getFromAccountData(AccountData accountData) =>
      accountData.actionEvents;
}
