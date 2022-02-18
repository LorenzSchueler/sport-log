import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/action/all.dart';

class ActionTable extends DbAccessor<Action> {
  @override
  DbSerializer<Action> get serde => DbActionSerializer();

  @override
  final Table table = Table(Tables.action, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.text(Keys.name).check("length(${Keys.name}) >= 2"),
    Column.int(Keys.actionProviderId)
        .references(Tables.actionProvider, onDelete: OnAction.cascade),
    Column.text(Keys.description).nullable(),
    Column.int(Keys.createBefore).check("${Keys.createBefore} >= 0"),
    Column.int(Keys.deleteAfter).check("${Keys.deleteAfter} >= 0"),
  ]);
}

class ActionEventTable extends DbAccessor<ActionEvent> {
  @override
  DbSerializer<ActionEvent> get serde => DbActionEventSerializer();

  @override
  final Table table = Table(Tables.actionEvent, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.int(Keys.actionId)
        .references(Tables.action, onDelete: OnAction.cascade),
    Column.text(Keys.datetime),
    Column.text(Keys.arguments).nullable(),
    Column.int(Keys.enabled).check("${Keys.enabled} in (0,1)"),
  ]);
}

class ActionRuleTable extends DbAccessor<ActionRule> {
  @override
  DbSerializer<ActionRule> get serde => DbActionRuleSerializer();

  @override
  final Table table = Table(Tables.actionRule, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.int(Keys.actionId)
        .references(Tables.action, onDelete: OnAction.cascade),
    Column.int(Keys.weekday).check("${Keys.weekday} between 0 and 6"),
    Column.text(Keys.time),
    Column.text(Keys.arguments).nullable(),
    Column.int(Keys.enabled).check("${Keys.enabled} in (0,1)"),
  ]);
}

class ActionProviderTable extends DbAccessor<ActionProvider> {
  @override
  DbSerializer<ActionProvider> get serde => DbActionProviderSerializer();

  @override
  final Table table = Table(Tables.actionProvider, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.text(Keys.name).check("length(${Keys.name}) between 2 and 80"),
    Column.text(Keys.password)
        .check("length(${Keys.password}) between 2 and 96"),
    Column.int(Keys.platformId)
        .references(Tables.platform, onDelete: OnAction.cascade),
    Column.text(Keys.description).nullable()
  ]);
}
