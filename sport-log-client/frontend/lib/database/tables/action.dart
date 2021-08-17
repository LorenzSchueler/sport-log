
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/action/all.dart';

class ActionTable extends Table<Action> {
  @override DbSerializer<Action> get serde => DbActionSerializer();
  @override String get setupSql => '''
create table action (
    id integer primary key,
    name text not null check (length(name) >= 2),
    action_provider_id integer not null references action_provider(id) on delete cascade,
    description text,
    create_before integer not null check (create_before >= 0), -- hours
    delete_after integer not null check (delete_after >= 0), --hours
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    unique (action_provider_id, name, deleted)
);
  ''';
  @override String get tableName => 'action';
}

class ActionEventTable extends Table<ActionEvent> {
  @override DbSerializer<ActionEvent> get serde => DbActionEventSerializer();
  @override String get setupSql => '''
create table action_event (
    id integer primary key,
    user_id integer not null,
    action_id integer not null references action(id) on delete cascade,
    datetime text not null,
    enabled integer not null check(enabled in (0, 1)),
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    unique (user_id, action_id, datetime, deleted)
);
  ''';
  @override String get tableName => 'action_event';
}

class ActionRuleTable extends Table<ActionRule> {
  @override DbSerializer<ActionRule> get serde => DbActionRuleSerializer();
  @override String get setupSql => '''
create table action_rule (
    id integer primary key,
    user_id integer not null,
    action_id bigint not null references action(id) on delete cascade,
    weekday integer not null check(weekday between 0 and 6), 
    time text not null,
    enabled integer not null check(enabled in (0, 1)),
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    unique (user_id, action_id, weekday, time, deleted)
);
  ''';
  @override String get tableName => 'action_rule';
}

class ActionProviderTable extends Table<ActionProvider> {
  @override DbSerializer<ActionProvider> get serde => DbActionProviderSerializer();
  @override String get setupSql => '''
create table action_provider (
    id integer primary key,
    name text not null check(length(name) >= 2),
    password text not null check(length(password) <= 96),
    platform_id integer not null references platform(id) on delete cascade,
    description text,
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    unique (name, deleted)
);
  ''';
  @override String get tableName => 'action_provider';
}