import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconTable extends TableAccessor<Metcon> {
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
      Column.int(Columns.userId)..nullable(),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.int(Columns.metconType)..checkBetween(0, 2),
      Column.int(Columns.rounds)
        ..nullable()
        ..checkGe(1),
      Column.int(Columns.timecap)
        ..nullable()
        ..checkGt(0),
      Column.text(Columns.description)..nullable()
    ],
    uniqueColumns: [
      [Columns.name]
    ],
  );

  @override
  Future<List<Metcon>> getNonDeleted() async {
    final result = await database.query(
      tableName,
      where: notDeleted,
      orderBy: "$tableName.${Columns.name} COLLATE NOCASE",
    );
    return result.map(serde.fromDbRecord).toList();
  }
}

class MetconMovementTable extends TableAccessor<MetconMovement> {
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
      [Columns.metconId, Columns.movementNumber]
    ],
  );

  Future<void> setSynchronizedByMetcon(Int64 id) async {
    database.update(
      tableName,
      TableAccessor.synchronized,
      where: '${Columns.metconId} = ?',
      whereArgs: [id.toInt()],
    );
  }

  Future<List<MetconMovement>> getByMetcon(Int64 id) async {
    final result = await database.query(
      tableName,
      where: '${Columns.metconId} = ? AND ${Columns.deleted} = 0',
      whereArgs: [id.toInt()],
      orderBy: Columns.movementNumber,
    );
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByMetcon(Int64 id) async {
    await database.update(
      tableName,
      {Columns.deleted: 1},
      where: '${Columns.deleted} = 0 AND ${Columns.metconId} = ?',
      whereArgs: [id.toInt()],
    );
  }
}

class MetconSessionTable extends TableAccessor<MetconSession> {
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
      Column.int(Columns.userId),
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
      Column.text(Columns.comments)..nullable()
    ],
    uniqueColumns: [
      [Columns.metconId, Columns.datetime]
    ],
  );

  Future<bool> existsByMetcon(Int64 id) async {
    return (await database.rawQuery(
      '''select 1 from $tableName
            where ${Columns.metconId} = ${id.toInt()}
              and ${Columns.deleted} = 0''',
    ))
        .isNotEmpty;
  }

  Future<List<MetconSession>> getByTimerangeAndMovement({
    Int64? movementIdValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await database.rawQuery('''
      SELECT
        ${table.allColumns}
      FROM $tableName
      WHERE $tableName.${Columns.deleted} = 0
        ${fromFilter(from)}
        ${untilFilter(until)}
        ${movementIdFilter(movementIdValue)}
      $groupById
      $orderByDatetime
      ;
    ''', [
      if (from != null) from.toString(),
      if (until != null) until.toString(),
      if (movementIdValue != null) movementIdValue.toInt(),
    ]);
    return records
        .map((e) => serde.fromDbRecord(e, prefix: table.prefix))
        .toList();
  }
}
