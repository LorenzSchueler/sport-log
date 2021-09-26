import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconTable extends DbAccessor<Metcon> {
  @override
  List<String> get setupSql => [
        '''
create table $tableName (
    user_id integer,
    name text check (length(name) <= 80),
    metcon_type integer not null check (metcon_type between 0 and 2),
    rounds integer check (rounds >= 1),
    timecap integer check (timecap > 0), -- seconds
    description text,
    $idAndDeletedAndStatus
);
  ''',
        updateTrigger,
      ];

  @override
  DbSerializer<Metcon> get serde => DbMetconSerializer();

  @override
  String get tableName => Tables.metcon;
}

class MetconMovementTable extends DbAccessor<MetconMovement> {
  @override
  DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();

  @override
  List<String> get setupSql => [_table.setupSql(), updateTrigger];

  final Table _table = Table(
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

  @override
  String get tableName => _table.name;

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
  List<String> get setupSql => [
        '''
create table $tableName (
    user_id integer not null,
    metcon_id integer not null references metcon(id) on delete no action,
    datetime text not null default (datetime('now')),
    time integer check (time > 0), -- seconds
    rounds integer check (rounds >= 0),
    reps integer check (reps >= 0),
    rx integer not null default 1 check (rx in (0, 1)),
    comments text,
    $idAndDeletedAndStatus
);
  ''',
        updateTrigger,
      ];

  @override
  String get tableName => Tables.metconSession;

  Future<bool> existsByMetcon(Int64 id) async {
    return (await database.rawQuery('''select 1 from $tableName
            where ${Keys.metconId} = ${id.toInt()}
              and ${Keys.deleted} = 0''')).isNotEmpty;
  }
}
