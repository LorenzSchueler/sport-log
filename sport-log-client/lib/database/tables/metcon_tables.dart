import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/all.dart';

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
      orderBy: orderByName,
    );
    return result.map(serde.fromDbRecord).toList();
  }

  Future<List<Metcon>> getByName(
    String? byName, {
    bool cardioOnly = false,
  }) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        nameFilter(byName),
        cardioOnly ? "${Columns.cardio} = true" : ""
      ]),
      orderBy: orderByName,
    );
    return records.map((r) => serde.fromDbRecord(r)).toList();
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

  Future<void> setSynchronizedByMetcon(Metcon metcon) async {
    await database.update(
      tableName,
      TableAccessor.synchronized,
      where: '${Columns.metconId} = ?',
      whereArgs: [metcon.id.toInt()],
    );
  }

  Future<List<MetconMovement>> getByMetcon(Metcon metcon) async {
    final result = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.metconId} = ?',
      ]),
      whereArgs: [metcon.id.toInt()],
      orderBy: Columns.movementNumber,
    );
    return result.map(serde.fromDbRecord).toList();
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

  Future<bool> existsByMetcon(Metcon metcon) async {
    return (await database.rawQuery(
      '''select 1 from $tableName
            where ${Columns.metconId} = ${metcon.id.toInt()}
              and ${Columns.deleted} = 0''',
    ))
        .isNotEmpty;
  }

  Future<List<MetconSession>> getByTimerangeAndMetcon({
    Metcon? metconValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        fromFilter(from),
        untilFilter(until),
        metconValue == null ? "" : "${Columns.metconId} = ${metconValue.id}"
      ]),
      groupBy: groupById,
      orderBy: orderByDatetime,
    );
    return records.map((e) => serde.fromDbRecord(e)).toList();
  }
}
