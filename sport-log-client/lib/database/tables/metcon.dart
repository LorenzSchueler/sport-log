import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconTable extends Table<Metcon> {
  @override
  String get setupSql => '''
create table metcon (
    user_id integer,
    name text check (length(name) <= 80),
    metcon_type integer not null check (metcon_type between 0 and 2),
    rounds integer check (rounds >= 1),
    timecap integer check (timecap > 0), -- seconds
    description text,
    $idAndDeletedAndStatus
);
  ''';

  @override
  DbSerializer<Metcon> get serde => DbMetconSerializer();

  @override
  String get tableName => 'metcon';
}

class MetconMovementTable extends Table<MetconMovement> {
  @override
  DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();

  @override
  String get setupSql => '''
create table metcon_movement (
    metcon_id integer not null references metcon(id) on delete cascade,
    movement_id integer not null references movement(id) on delete no action,
    movement_number integer not null check (movement_number >= 0),
    count integer not null check (count >= 1),
    movement_unit integer not null check (movement_unit between 0 and 6),
    weight real check (weight > 0),
    $idAndDeletedAndStatus
);
  ''';

  @override
  String get tableName => 'metcon_movement';

  Future<void> setSynchronizedByMetcon(Int64 id) async {
    database.update(tableName, Table.synchronized,
        where: '${Keys.metconId} = ?', whereArgs: [id.toInt()]);
  }

  Future<List<MetconMovement>> getByMetcon(Int64 id) async {
    final result = await database.query(tableName,
        where: '${Keys.metconId} = ? AND ${Keys.deleted} = 0',
        whereArgs: [id.toInt()]);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByMetcon(Int64 id) async {
    await database.update(tableName, {Keys.deleted: 1},
        where: '${Keys.deleted} = 0 AND ${Keys.metconId} = ?',
        whereArgs: [id.toInt()]);
  }
}

class MetconSessionTable extends Table<MetconSession> {
  @override
  DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();

  @override
  String get setupSql => '''
create table metcon_session (
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
  ''';

  @override
  String get tableName => 'metcon_session';

  Future<bool> existsByMetcon(Int64 id) async {
    return (await database.rawQuery('''select 1 from $tableName
            where ${Keys.metconId} = ${id.toInt()}
              and ${Keys.deleted} = 0''')).isNotEmpty;
  }
}
