import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/action/all.dart';
import 'package:sport_log/models/platform/platform.dart';

class ActionTable extends TableAccessor<Action> {
  factory ActionTable() => _instance;

  ActionTable._();

  static final _instance = ActionTable._();

  @override
  DbSerializer<Action> get serde => DbActionSerializer();

  @override
  final Table table = Table(
    name: Tables.action,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.int(Columns.actionProviderId)
        ..references(Tables.actionProvider, onDelete: OnAction.cascade),
      Column.text(Columns.description)..nullable(),
    ],
    uniqueColumns: [
      [Columns.actionProviderId, Columns.name]
    ],
  );

  Future<List<Action>> getByActionProvider(
    ActionProvider actionProvider,
  ) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.actionProviderId} = ?',
      ]),
      whereArgs: [actionProvider.id.toInt()],
      orderBy: orderByName,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class ActionEventTable extends TableAccessor<ActionEvent> {
  factory ActionEventTable() => _instance;

  ActionEventTable._();

  static final _instance = ActionEventTable._();

  @override
  DbSerializer<ActionEvent> get serde => DbActionEventSerializer();

  @override
  final Table table = Table(
    name: Tables.actionEvent,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.int(Columns.actionId)
        ..references(Tables.action, onDelete: OnAction.cascade),
      Column.text(Columns.datetime),
      Column.text(Columns.arguments)..nullable(),
      Column.int(Columns.enabled)..checkIn(<int>[0, 1]),
    ],
    uniqueColumns: [
      [Columns.actionId, Columns.datetime]
    ],
  );

  Future<List<ActionEvent>> getByActionProvider(
    ActionProvider actionProvider,
  ) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.actionId} in (select ${Columns.id} from ${Tables.action} where ${TableAccessor.combineFilter([
              TableAccessor.notDeletedOfTable(Tables.action),
              "${Columns.actionProviderId} = ?"
            ])})',
      ]),
      whereArgs: [actionProvider.id.toInt()],
      orderBy: orderByDatetimeAsc,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class ActionRuleTable extends TableAccessor<ActionRule> {
  factory ActionRuleTable() => _instance;

  ActionRuleTable._();

  static final _instance = ActionRuleTable._();

  @override
  DbSerializer<ActionRule> get serde => DbActionRuleSerializer();

  @override
  final Table table = Table(
    name: Tables.actionRule,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.int(Columns.actionId)
        ..references(Tables.action, onDelete: OnAction.cascade),
      Column.int(Columns.weekday)..checkBetween(0, 6),
      Column.text(Columns.time),
      Column.text(Columns.arguments)..nullable(),
      Column.int(Columns.enabled)..checkIn(<int>[0, 1]),
    ],
    uniqueColumns: [
      [Columns.actionId, Columns.weekday, Columns.time]
    ],
  );

  Future<List<ActionRule>> getByActionProvider(
    ActionProvider actionProvider,
  ) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.actionId} in (select ${Columns.id} from ${Tables.action} where ${TableAccessor.combineFilter([
              TableAccessor.notDeletedOfTable(Tables.action),
              "${Columns.actionProviderId} = ?"
            ])})',
      ]),
      whereArgs: [actionProvider.id.toInt()],
      orderBy: Columns.weekday,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class ActionProviderTable extends TableAccessor<ActionProvider> {
  factory ActionProviderTable() => _instance;

  ActionProviderTable._();

  static final _instance = ActionProviderTable._();

  @override
  DbSerializer<ActionProvider> get serde => DbActionProviderSerializer();

  @override
  final Table table = Table(
    name: Tables.actionProvider,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.int(Columns.platformId)
        ..references(Tables.platform, onDelete: OnAction.cascade),
      Column.text(Columns.description)..nullable()
    ],
    uniqueColumns: [
      [Columns.name]
    ],
  );

  Future<List<ActionProvider>> getByPlatform(Platform platform) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        "${Columns.platformId} = ?",
      ]),
      whereArgs: [platform.id.toInt()],
    );
    return records.map(serde.fromDbRecord).toList();
  }
}
