import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/action/all.dart';

class ActionTable extends TableAccessor<Action> {
  @override
  DbSerializer<Action> get serde => DbActionSerializer();

  @override
  final Table table = Table(Tables.action, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.text(Columns.name).check("length(${Columns.name}) >= 2"),
    Column.int(Columns.actionProviderId)
        .references(Tables.actionProvider, onDelete: OnAction.cascade),
    Column.text(Columns.description).nullable(),
    Column.int(Columns.createBefore).check("${Columns.createBefore} >= 0"),
    Column.int(Columns.deleteAfter).check("${Columns.deleteAfter} >= 0"),
  ]);
}

class ActionEventTable extends TableAccessor<ActionEvent> {
  @override
  DbSerializer<ActionEvent> get serde => DbActionEventSerializer();

  @override
  final Table table = Table(Tables.actionEvent, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.int(Columns.actionId)
        .references(Tables.action, onDelete: OnAction.cascade),
    Column.text(Columns.datetime),
    Column.text(Columns.arguments).nullable(),
    Column.int(Columns.enabled).check("${Columns.enabled} in (0,1)"),
  ]);
}

class ActionRuleTable extends TableAccessor<ActionRule> {
  @override
  DbSerializer<ActionRule> get serde => DbActionRuleSerializer();

  @override
  final Table table = Table(Tables.actionRule, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.int(Columns.actionId)
        .references(Tables.action, onDelete: OnAction.cascade),
    Column.int(Columns.weekday).check("${Columns.weekday} between 0 and 6"),
    Column.text(Columns.time),
    Column.text(Columns.arguments).nullable(),
    Column.int(Columns.enabled).check("${Columns.enabled} in (0,1)"),
  ]);
}

class ActionProviderTable extends TableAccessor<ActionProvider> {
  @override
  DbSerializer<ActionProvider> get serde => DbActionProviderSerializer();

  @override
  final Table table = Table(Tables.actionProvider, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.text(Columns.name).check("length(${Columns.name}) between 2 and 80"),
    Column.text(Columns.password)
        .check("length(${Columns.password}) between 2 and 96"),
    Column.int(Columns.platformId)
        .references(Tables.platform, onDelete: OnAction.cascade),
    Column.text(Columns.description).nullable()
  ]);
}
