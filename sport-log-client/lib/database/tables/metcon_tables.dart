import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconTable extends TableAccessor<Metcon> {
  @override
  DbSerializer<Metcon> get serde => DbMetconSerializer();

  @override
  final Table table = Table(Tables.metcon, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId).nullable(),
    Column.text(Columns.name).nullable().check("length(${Columns.name}) <= 80"),
    Column.int(Columns.metconType)
        .check("${Columns.metconType} between 0 and 2"),
    Column.int(Columns.rounds).nullable().check("${Columns.rounds} >= 1"),
    Column.int(Columns.timecap).nullable().check("${Columns.timecap} > 0"),
    Column.text(Columns.description).nullable()
  ]);
}

class MetconMovementTable extends TableAccessor<MetconMovement> {
  @override
  DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();

  @override
  final Table table = Table(
    Tables.metconMovement,
    columns: [
      Column.int(Columns.id).primaryKey(),
      Column.bool(Columns.deleted).withDefault('0'),
      Column.int(Columns.syncStatus)
          .withDefault('2')
          .check('${Columns.syncStatus} IN (0, 1, 2)'),
      Column.int(Columns.metconId)
          .references(Tables.metcon, onDelete: OnAction.cascade),
      Column.int(Columns.movementId)
          .references(Tables.movement, onDelete: OnAction.noAction),
      Column.int(Columns.movementNumber)
          .check('${Columns.movementNumber} >= 0'),
      Column.int(Columns.count).check('${Columns.count} >= 1'),
      Column.real(Columns.weight).nullable().check('${Columns.weight} > 0'),
      Column.int(Columns.distanceUnit)
          .nullable()
          .check('${Columns.distanceUnit} BETWEEN 0 AND 4'),
    ],
  );

  Future<void> setSynchronizedByMetcon(Int64 id) async {
    database.update(tableName, TableAccessor.synchronized,
        where: '${Columns.metconId} = ?', whereArgs: [id.toInt()]);
  }

  Future<List<MetconMovement>> getByMetcon(Int64 id) async {
    final result = await database.query(tableName,
        where: '${Columns.metconId} = ? AND ${Columns.deleted} = 0',
        whereArgs: [id.toInt()],
        orderBy: Columns.movementNumber);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByMetcon(Int64 id) async {
    await database.update(tableName, {Columns.deleted: 1},
        where: '${Columns.deleted} = 0 AND ${Columns.metconId} = ?',
        whereArgs: [id.toInt()]);
  }
}

class MetconSessionTable extends TableAccessor<MetconSession> {
  @override
  DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();

  @override
  final Table table = Table(Tables.metconSession, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.text(Columns.metconId)
        .references(Tables.metcon, onDelete: OnAction.noAction),
    Column.text(Columns.datetime),
    Column.int(Columns.time).nullable().check("${Columns.time} > 0"),
    Column.int(Columns.rounds).nullable().check("${Columns.rounds} >= 0"),
    Column.int(Columns.reps).nullable().check("${Columns.reps} >= 0"),
    Column.bool(Columns.rx).check("${Columns.rx} in (0, 1)"),
    Column.text(Columns.comments).nullable()
  ]);

  Future<bool> existsByMetcon(Int64 id) async {
    return (await database.rawQuery('''select 1 from $tableName
            where ${Columns.metconId} = ${id.toInt()}
              and ${Columns.deleted} = 0''')).isNotEmpty;
  }
}
