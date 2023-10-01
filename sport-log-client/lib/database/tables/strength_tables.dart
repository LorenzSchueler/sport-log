import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/strength_records.dart';

class StrengthSessionTable extends TableAccessor<StrengthSession> {
  factory StrengthSessionTable() => _instance;

  StrengthSessionTable._();

  static final _instance = StrengthSessionTable._();

  @override
  DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();

  @override
  final Table table = Table(
    name: Tables.strengthSession,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.text(Columns.datetime),
      Column.int(Columns.movementId)
        ..references(Tables.movement, onDelete: OnAction.cascade),
      Column.int(Columns.interval)
        ..nullable()
        ..checkGt(0),
      Column.text(Columns.comments)..nullable(),
    ],
    uniqueColumns: [],
  );
}

final eormTable = Table(
  name: Tables.eorm,
  columns: [
    Column.int(Columns.eormReps)
      ..primaryKey()
      ..checkGe(1),
    Column.real(Columns.eormPercentage)..checkGt(0),
  ],
  uniqueColumns: [],
  rawSql: [
    "insert into ${Tables.eorm} (${Columns.eormReps}, ${Columns.eormPercentage}) values $eormValuesSql;",
  ],
);

class StrengthSetTable extends TableAccessor<StrengthSet> {
  factory StrengthSetTable() => _instance;

  StrengthSetTable._();

  static final _instance = StrengthSetTable._();

  @override
  DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();

  @override
  final Table table = Table(
    name: Tables.strengthSet,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.strengthSessionId)
        ..references(Tables.strengthSession, onDelete: OnAction.cascade),
      Column.int(Columns.setNumber)..checkGe(0),
      Column.int(Columns.count)..checkGe(1),
      Column.real(Columns.weight)
        ..nullable()
        ..checkGt(0),
    ],
    uniqueColumns: [
      [Columns.strengthSessionId, Columns.setNumber],
    ],
  );

  Future<StrengthSet?> getLastByMovement(Movement movement) async {
    final records = await database.rawQuery("""
      select * from $tableName
      join ${Tables.strengthSession} 
      on $tableName.${Columns.strengthSessionId} = ${Tables.strengthSession}.${Columns.id}
      where ${TableAccessor.combineFilter([
          notDeleted,
          TableAccessor.notDeletedOfTable(Tables.strengthSession),
          "${Tables.strengthSession}.${Columns.movementId} = ${movement.id.toInt()}",
        ])}
      order by ${Tables.strengthSession}.${Columns.datetime} desc, $tableName.${Columns.setNumber} desc
      limit 1;
      """);
    return records.map(serde.fromDbRecord).firstOrNull;
  }

  Future<List<StrengthSet>> getByStrengthSession(
    StrengthSession strengthSession,
  ) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.strengthSessionId} = ?',
      ]),
      whereArgs: [strengthSession.id.toInt()],
      orderBy: Columns.setNumber,
    );
    return records.map(serde.fromDbRecord).toList();
  }

  Future<StrengthRecords> getStrengthRecords() async {
    final records = await database.rawQuery(
      """
      select ${Tables.movement}.${Columns.id} as ${Columns.movementId}, 
        max(${Tables.strengthSet}.${Columns.weight}) as ${Columns.maxWeight}, 
        max(${Tables.strengthSet}.${Columns.count}) as ${Columns.maxCount}, 
        max(${Tables.strengthSet}.${Columns.weight} / ${Tables.eorm}.${Columns.eormPercentage}) as ${Columns.maxEorm}
      from ${Tables.strengthSet}
      join ${Tables.strengthSession} on ${Tables.strengthSet}.${Columns.strengthSessionId} = ${Tables.strengthSession}.${Columns.id}
      join ${Tables.movement} on ${Tables.strengthSession}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
      left join ${Tables.eorm} on ${Tables.strengthSet}.${Columns.count} = ${Tables.eorm}.${Columns.eormReps} 
        and ${Tables.strengthSet}.${Columns.count} <= 10 
        and ${Tables.movement}.${Columns.dimension} = ${MovementDimension.reps.index}
      where ${TableAccessor.combineFilter([
            notDeleted,
            TableAccessor.notDeletedOfTable(Tables.strengthSession),
            TableAccessor.notDeletedOfTable(Tables.movement),
          ])}
      group by ${Tables.movement}.${Columns.id}
      """,
    );
    return {
      for (final record in records)
        Int64(record[Columns.movementId]! as int):
            StrengthRecord.fromDbRecord(record),
    };
  }
}

class StrengthSessionDescriptionTable {
  factory StrengthSessionDescriptionTable() => _instance;

  StrengthSessionDescriptionTable._();

  static final _instance = StrengthSessionDescriptionTable._();

  static final StrengthSessionTable _strengthSessionTable =
      StrengthSessionTable();
  static final MovementTable _movementTable = MovementTable();
  static final StrengthSetTable _strengthSetTable = StrengthSetTable();

  Future<StrengthSessionDescription?> getById(Int64 idValue) async {
    final records = await AppDatabase.database.rawQuery(
      '''
      SELECT
        ${_strengthSessionTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM ${Tables.strengthSession}
        JOIN ${Tables.movement} ON ${Tables.movement}.${Columns.id} = ${Tables.strengthSession}.${Columns.movementId}
      WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.strengthSession),
            TableAccessor.notDeletedOfTable(Tables.movement),
            "${Tables.strengthSession}.${Columns.id} = ?",
          ])}
    ''',
      [idValue.toInt()],
    );
    if (records.isEmpty) {
      return null;
    }
    final strengthSession = _strengthSessionTable.serde.fromDbRecord(
      records.first,
      prefix: _strengthSessionTable.table.prefix,
    );
    return StrengthSessionDescription(
      session: strengthSession,
      movement: _movementTable.serde
          .fromDbRecord(records.first, prefix: _movementTable.table.prefix),
      sets: await _strengthSetTable.getByStrengthSession(strengthSession),
    );
  }

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovementAndComment({
    DateTime? from,
    DateTime? until,
    Movement? movement,
    String? comment,
  }) async {
    final records = await AppDatabase.database.rawQuery(
      '''
      SELECT
        ${_strengthSessionTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM ${Tables.strengthSession}
      JOIN ${Tables.movement} ON ${Tables.movement}.${Columns.id} = ${Tables.strengthSession}.${Columns.movementId}
      WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.movement),
            TableAccessor.notDeletedOfTable(Tables.strengthSession),
            TableAccessor.fromFilterOfTable(Tables.strengthSession, from),
            TableAccessor.untilFilterOfTable(Tables.strengthSession, until),
            TableAccessor.movementIdFilterOfTable(
              Tables.strengthSession,
              movement,
            ),
            TableAccessor.commentFilterOfTable(Tables.strengthSession, comment),
          ])}
      GROUP BY ${TableAccessor.groupByIdOfTable(Tables.strengthSession)}
      ORDER BY ${TableAccessor.orderByDatetimeOfTable(Tables.strengthSession)}
      ;
    ''',
    );
    final strengthSessionDescriptions = <StrengthSessionDescription>[];
    for (final record in records) {
      final session = _strengthSessionTable.serde
          .fromDbRecord(record, prefix: _strengthSessionTable.table.prefix);
      strengthSessionDescriptions.add(
        StrengthSessionDescription(
          session: session,
          sets: await _strengthSetTable.getByStrengthSession(session),
          movement: _movementTable.serde
              .fromDbRecord(record, prefix: _movementTable.table.prefix),
        ),
      );
    }
    return strengthSessionDescriptions;
  }
}
