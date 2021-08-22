
import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sqflite/sqflite.dart';

class MetconTable extends Table<Metcon> {
  @override String get setupSql => '''
create table metcon (
    id integer primary key,
    user_id integer,
    name text check (length(name) <= 80),
    metcon_type integer not null check (metcon_type between 0 and 2),
    rounds integer check (rounds >= 1),
    timecap integer check (timecap > 0), -- seconds
    description text,
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (user_id, name, deleted)
);
  ''';
  @override DbSerializer<Metcon> get serde => DbMetconSerializer();
  @override String get tableName => 'metcon';

  late MetconMovementTable metconMovements;

  @override
  DbResult<void> deleteSingle(Int64 id, [Transaction? txn]) async {
    assert(txn == null);
    return voidRequest(() async {
      await database.transaction((transaction) async {
        metconMovements.deleteByMetcon(id, transaction);
        super.deleteSingle(id, transaction);
      });
    });
  }

  @override
  DbResult<void> deleteMultiple(List<Int64> ids, [Transaction? txn]) async {
    assert(txn == null);
    for (final id in ids) {
      final result = await deleteSingle(id);
      if (result.isFailure) {
        return result;
      }
    }
    return Success(null);
  }

  DbResult<void> updateFull(MetconDescription metconDescription) async {
    if (!metconDescription.isValid()) {
      return Failure(DbError.validationFailed);
    }
    return voidRequest(() async {
      await database.transaction((txn) async {
        updateSingle(metconDescription.metcon, txn);
        final result = await metconMovements.get(
          where: "${Keys.metconId} = ?",
          whereArgs: [metconDescription.metcon.id.toInt()],
          transaction: txn,
        );
        if (result.isFailure) {
          throw result.failure;
        }
        final Set<Int64> oldIds = result.success.map((mm) => mm.id).toSet();
        List<MetconMovement> toCreate = [], toUpdate = [];

        for (final mm in metconDescription.moves) {
          oldIds.contains(mm.id) ? toUpdate.add(mm) : toCreate.add(mm);
        }

        List<Int64> toDelete = oldIds.difference(
            toUpdate.map((mm) => mm.id).toSet()).toList();

        metconMovements.deleteMultiple(toDelete, txn);
        metconMovements.updateMultiple(toUpdate, txn);
        metconMovements.createMultiple(toCreate, true, txn);
      });
    });
  }

  DbResult<void> createFull(MetconDescription metconDescription, bool isNew) async {
    return voidRequest(() async {
      await database.transaction((txn) async {
        createSingle(metconDescription.metcon, isNew, txn);
        metconMovements.createMultiple(metconDescription.moves, isNew, txn);
      });
    });
  }
}

class MetconMovementTable extends Table<MetconMovement> {
  @override DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();
  @override String get setupSql => '''
create table metcon_movement (
    id integer primary key,
    metcon_id integer not null references metcon(id) on delete cascade,
    movement_id integer not null references movement(id) on delete no action,
    movement_number integer not null check (movement_number >= 0),
    count integer not null check (count >= 1),
    movement_unit integer not null check (movement_unit between 0 and 6),
    weight real check (weight > 0),
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (metcon_id, movement_number, deleted)
);
  ''';
  @override String get tableName => 'metcon_movement';

  DbResult<void> deleteByMetcon(Int64 id, [Transaction? txn]) async {
    return voidRequest(() async {
      (txn ?? database).update(
        tableName,
        {Keys.deleted: 1},
        where: '${Keys.metconId} = ?',
        whereArgs: [id.toInt()]
      );
    });
  }
}

class MetconSessionTable extends Table<MetconSession> {
  @override DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();
  @override
  String get setupSql => '''
create table metcon_session (
    id integer primary key,
    user_id integer not null,
    metcon_id integer not null references metcon(id) on delete no action,
    datetime text not null default (datetime('now')),
    time integer check (time > 0), -- seconds
    rounds integer check (rounds >= 0),
    reps integer check (reps >= 0),
    rx integer not null default 1 check (rx in (0, 1)),
    comments text,
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (user_id, metcon_id, datetime, deleted)
);
  ''';
  @override String get tableName => 'metcon_session';
}
