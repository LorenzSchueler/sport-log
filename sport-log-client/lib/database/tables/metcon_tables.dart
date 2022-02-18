import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconTable extends DbAccessor<Metcon> {
  @override
  DbSerializer<Metcon> get serde => DbMetconSerializer();

  @override
  final Table table = Table(Tables.metcon, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId).nullable(),
    Column.text(Keys.name).nullable().check("length(${Keys.name}) <= 80"),
    Column.int(Keys.metconType).check("${Keys.metconType} between 0 and 2"),
    Column.int(Keys.rounds).nullable().check("${Keys.rounds} >= 1"),
    Column.int(Keys.timecap).nullable().check("${Keys.timecap} > 0"),
    Column.text(Keys.description).nullable()
  ]);
}

class MetconMovementTable extends DbAccessor<MetconMovement> {
  @override
  DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();

  @override
  final Table table = Table(
    Tables.metconMovement,
    withColumns: [
      Column.int(Keys.id).primaryKey(),
      Column.bool(Keys.deleted).withDefault('0'),
      Column.int(Keys.syncStatus)
          .withDefault('2')
          .check('${Keys.syncStatus} IN (0, 1, 2)'),
      Column.int(Keys.metconId)
          .references(Tables.metcon, onDelete: OnAction.cascade),
      Column.int(Keys.movementId)
          .references(Tables.movement, onDelete: OnAction.noAction),
      Column.int(Keys.movementNumber).check('${Keys.movementNumber} >= 0'),
      Column.int(Keys.count).check('${Keys.count} >= 1'),
      Column.real(Keys.weight).nullable().check('${Keys.weight} > 0'),
      Column.int(Keys.distanceUnit)
          .nullable()
          .check('${Keys.distanceUnit} BETWEEN 0 AND 4'),
    ],
  );

  Future<void> setSynchronizedByMetcon(Int64 id) async {
    database.update(tableName, DbAccessor.synchronized,
        where: '${Keys.metconId} = ?', whereArgs: [id.toInt()]);
  }

  Future<List<MetconMovement>> getByMetcon(Int64 id) async {
    final result = await database.query(tableName,
        where: '${Keys.metconId} = ? AND ${Keys.deleted} = 0',
        whereArgs: [id.toInt()],
        orderBy: Keys.movementNumber);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByMetcon(Int64 id) async {
    await database.update(tableName, {Keys.deleted: 1},
        where: '${Keys.deleted} = 0 AND ${Keys.metconId} = ?',
        whereArgs: [id.toInt()]);
  }
}

class MetconSessionTable extends DbAccessor<MetconSession> {
  @override
  DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();

  @override
  final Table table = Table(Tables.metconSession, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.text(Keys.metconId)
        .references(Tables.metcon, onDelete: OnAction.noAction),
    Column.text(Keys.datetime),
    Column.int(Keys.time).nullable().check("${Keys.time} > 0"),
    Column.int(Keys.rounds).nullable().check("${Keys.rounds} >= 0"),
    Column.int(Keys.reps).nullable().check("${Keys.reps} >= 0"),
    Column.bool(Keys.rx).check("${Keys.rx} in (0, 1)"),
    Column.text(Keys.comments).nullable()
  ]);

  Future<bool> existsByMetcon(Int64 id) async {
    return (await database.rawQuery('''select 1 from $tableName
            where ${Keys.metconId} = ${id.toInt()}
              and ${Keys.deleted} = 0''')).isNotEmpty;
  }
}
