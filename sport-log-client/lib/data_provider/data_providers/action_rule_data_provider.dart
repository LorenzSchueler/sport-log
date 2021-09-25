import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/action/action_rule.dart';

class ActionRuleDataProvider extends DataProviderImpl<ActionRule>
    with ConnectedMethods<ActionRule> {
  @override
  final ApiAccessor<ActionRule> api = Api.instance.actionRules;

  @override
  final DbAccessor<ActionRule> db = AppDatabase.instance!.actionRules;
}
