
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/action/all.dart';

class ActionTable extends DbAccessor<Action> {
  @override DbSerializer<Action> get serde => DbActionSerializer();
  @override String get setupSql => '''
create table $tableName (
    name text not null check (length(name) >= 2),
    action_provider_id integer not null references action_provider(id) on delete cascade,
    description text,
    create_before integer not null check (create_before >= 0), -- hours
    delete_after integer not null check (delete_after >= 0), --hours
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => Tables.action;
}

class ActionEventTable extends DbAccessor<ActionEvent> {
  @override DbSerializer<ActionEvent> get serde => DbActionEventSerializer();
  @override String get setupSql => '''
create table $tableName (
    user_id integer not null,
    action_id integer not null references action(id) on delete cascade,
    datetime text not null,
    arguments text,
    enabled integer not null check(enabled in (0, 1)),
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => Tables.actionEvent;
}

class ActionRuleTable extends DbAccessor<ActionRule> {
  @override DbSerializer<ActionRule> get serde => DbActionRuleSerializer();
  @override String get setupSql => '''
create table $tableName (
    user_id integer not null,
    action_id bigint not null references action(id) on delete cascade,
    weekday integer not null check(weekday between 0 and 6), 
    time text not null,
    arguments text,
    enabled integer not null check(enabled in (0, 1)),
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => Tables.actionRule;
}

class ActionProviderTable extends DbAccessor<ActionProvider> {
  @override DbSerializer<ActionProvider> get serde => DbActionProviderSerializer();
  @override String get setupSql => '''
create table $tableName (
    name text not null check(length(name) between 2 and 80),
    password text not null check(length(password) between 1 and 96),
    platform_id integer not null references platform(id) on delete cascade,
    description text,
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => 'action_provider';
}