import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/action/action_event.dart';
import 'package:sport_log/models/action/action_rule.dart';

class ActionEventDataProvider extends DataProviderImpl<ActionEvent>
    with ConnectedMethods<ActionEvent> {
  static final instance = ActionEventDataProvider._();
  ActionEventDataProvider._();

  @override
  final ApiAccessor<ActionEvent> api = Api.instance.actionEvents;

  @override
  final DbAccessor<ActionEvent> db = AppDatabase.instance!.actionEvents;

  @override
  List<ActionEvent> getFromAccountData(AccountData accountData) =>
      accountData.actionEvents;
}

class ActionRuleDataProvider extends DataProviderImpl<ActionRule>
    with ConnectedMethods<ActionRule> {
  static final instance = ActionRuleDataProvider._();
  ActionRuleDataProvider._();

  @override
  final ApiAccessor<ActionRule> api = Api.instance.actionRules;

  @override
  final DbAccessor<ActionRule> db = AppDatabase.instance!.actionRules;

  @override
  List<ActionRule> getFromAccountData(AccountData accountData) =>
      accountData.actionRules;
}
