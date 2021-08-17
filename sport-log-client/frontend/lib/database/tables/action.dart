
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/action/all.dart';

class ActionTable extends Table<Action> {
  @override DbSerializer<Action> get serde => DbActionSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'action';
}

class ActionEventTable extends Table<ActionEvent> {
  @override DbSerializer<ActionEvent> get serde => DbActionEventSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'action_event';
}

class ActionRuleTable extends Table<ActionRule> {
  @override DbSerializer<ActionRule> get serde => DbActionRuleSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'action_rule';
}

class ActionProviderTable extends Table<ActionProvider> {
  @override DbSerializer<ActionProvider> get serde => DbActionProviderSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'action_provider';
}