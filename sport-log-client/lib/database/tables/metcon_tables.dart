import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';

class MetconTable extends TableAccessor<Metcon> {
  factory MetconTable() => _instance;

  MetconTable._();

  static final _instance = MetconTable._();

  @override
  DbSerializer<Metcon> get serde => DbMetconSerializer();

  @override
  final Table table = Table(
    name: Tables.metcon,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.bool(Columns.isDefaultMetcon),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.int(Columns.metconType)..checkBetween(0, 2),
      Column.int(Columns.rounds)
        ..nullable()
        ..checkGe(1),
      Column.int(Columns.timecap)
        ..nullable()
        ..checkGt(0),
      Column.text(Columns.description)..nullable(),
    ],
    uniqueColumns: [
      [Columns.name],
    ],
  );

  @override
  Future<List<Metcon>> getNonDeleted() async {
    final records = await database.query(
      tableName,
      where: notDeleted,
      orderBy: orderByName,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class MetconMovementTable extends TableAccessor<MetconMovement> {
  factory MetconMovementTable() => _instance;

  MetconMovementTable._();

  static final _instance = MetconMovementTable._();

  @override
  DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();

  @override
  final Table table = Table(
    name: Tables.metconMovement,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.metconId)
        ..references(Tables.metcon, onDelete: OnAction.cascade),
      Column.int(Columns.movementId)
        ..references(Tables.movement, onDelete: OnAction.noAction),
      Column.int(Columns.movementNumber)..checkGe(0),
      Column.int(Columns.count)..checkGe(1),
      Column.real(Columns.maleWeight)
        ..nullable()
        ..checkGt(0),
      Column.real(Columns.femaleWeight)
        ..nullable()
        ..checkGt(0),
      Column.int(Columns.distanceUnit)
        ..nullable()
        ..checkBetween(0, 4),
    ],
    uniqueColumns: [
      [Columns.metconId, Columns.movementNumber],
    ],
  );

  Future<void> setSynchronizedByMetcon(Metcon metcon) async {
    await database.update(
      tableName,
      TableAccessor.synchronized,
      where: '${Columns.metconId} = ?',
      whereArgs: [metcon.id.toInt()],
    );
  }

  Future<List<MetconMovement>> getByMetcon(Metcon metcon) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.metconId} = ?',
      ]),
      whereArgs: [metcon.id.toInt()],
      orderBy: Columns.movementNumber,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class MetconSessionTable extends TableAccessor<MetconSession> {
  factory MetconSessionTable() => _instance;

  MetconSessionTable._();

  static final _instance = MetconSessionTable._();

  @override
  DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();

  @override
  final Table table = Table(
    name: Tables.metconSession,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.metconId)
        ..references(Tables.metcon, onDelete: OnAction.noAction),
      Column.text(Columns.datetime),
      Column.int(Columns.time)
        ..nullable()
        ..checkGt(0),
      Column.int(Columns.rounds)
        ..nullable()
        ..checkGe(0),
      Column.int(Columns.reps)
        ..nullable()
        ..checkGe(0),
      Column.bool(Columns.rx)..checkIn(<int>[0, 1]),
      Column.text(Columns.comments)..nullable(),
    ],
    uniqueColumns: [],
  );

  Future<bool> existsByMetcon(Metcon metcon) async {
    return (await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        "${Columns.metconId} = ?",
      ]),
      whereArgs: [metcon.id.toInt()],
    ))
        .isNotEmpty;
  }

  Future<List<MetconSession>> getByTimerangeAndMetconAndComment({
    DateTime? from,
    DateTime? until,
    Metcon? metcon,
    String? comment,
  }) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        fromFilter(from),
        untilFilter(until),
        metcon == null ? "" : "${Columns.metconId} = ${metcon.id}",
        commentFilter(comment),
      ]),
      groupBy: groupById,
      orderBy: orderByDatetime,
    );
    return records.map((e) => serde.fromDbRecord(e)).toList();
  }

  Future<MetconRecords> getMetconRecords() async {
    final records = await database.rawQuery(
      """
      select 
        ${Tables.metconSession}.${Columns.metconId}, 
        min(${Tables.metconSession}.${Columns.time}) as ${Columns.time}, 
        max(${Tables.metconSession}.${Columns.rounds} * ${MetconRecord.multiplier} + ${Tables.metconSession}.${Columns.reps}) as ${Columns.roundsAndReps}
      from ${Tables.metconSession}
      where ${TableAccessor.combineFilter([
            notDeleted,
            "${Tables.metconSession}.${Columns.rx} = 1",
          ])} 
      group by ${Tables.metconSession}.${Columns.metconId}
      """,
    );
    return {
      for (final record in records)
        Int64(record[Columns.metconId]! as int):
            MetconRecord.fromDbRecord(record),
    };
  }
}
