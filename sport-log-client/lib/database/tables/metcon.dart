import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/extensions/result_extension.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sqflite/sqflite.dart';

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

  late MetconMovementTable metconMovements;
  late MetconSessionTable metconSessions;

  @override
  DbResult<void> deleteSingle(Int64 id,
      {Transaction? transaction, bool isSynchronized = false}) async {
    assert(transaction == null);
    return voidRequest(() async {
      await database.transaction((transaction) async {
        metconMovements.deleteByMetcon(id, transaction);
        super.deleteSingle(id,
            transaction: transaction, isSynchronized: isSynchronized);
      });
    });
  }

  @override
  DbResult<void> deleteMultiple(List<Int64> ids,
      {Transaction? transaction, bool isSynchronized = false}) async {
    assert(transaction == null);
    for (final id in ids) {
      final result = await deleteSingle(id, isSynchronized: isSynchronized);
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
        updateSingle(metconDescription.metcon, transaction: txn);
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

        List<Int64> toDelete =
            oldIds.difference(toUpdate.map((mm) => mm.id).toSet()).toList();

        metconMovements.deleteMultiple(toDelete, transaction: txn);
        metconMovements.updateMultiple(toUpdate, transaction: txn);
        metconMovements.createMultiple(toCreate, transaction: txn);
      });
    });
  }

  DbResult<void> createFull(MetconDescription metconDescription) async {
    return voidRequest(() async {
      await database.transaction((txn) async {
        createSingle(metconDescription.metcon, transaction: txn);
        metconMovements.createMultiple(metconDescription.moves,
            transaction: txn);
      });
    });
  }

  @override
  DbResult<void> setSynchronized(Int64 id, [Transaction? txn]) {
    assert(txn == null);
    return voidRequest(() async {
      return database.transaction((txn) async {
        super.setSynchronized(id, txn);
        metconMovements.setSynchronizedByMetcon(id, txn);
      });
    });
  }

  DbResult<List<MetconDescription>> getNonDeletedFull() async {
    return request<List<MetconDescription>>(() async {
      final result = await getNonDeleted();
      if (result.isFailure) {
        return Failure(result.failure);
      }
      return Success(await Future.wait(result.success.map((metcon) async {
        return MetconDescription(
            metcon: metcon,
            moves: (await metconMovements.getByMetcon(metcon.id)).or([]),
            // TODO: do this with a join
            hasReference: await metconSessions.existsByMetcon(metcon.id));
      })));
    });
  }
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

  DbResult<void> deleteByMetcon(Int64 id, [Transaction? txn]) async {
    return voidRequest(() async {
      (txn ?? database).update(tableName, {Keys.deleted: 1},
          where: '${Keys.metconId} = ?', whereArgs: [id.toInt()]);
    });
  }

  DbResult<void> setSynchronizedByMetcon(Int64 id, [Transaction? txn]) async {
    return voidRequest(() async {
      database.update(tableName, Table.synchronized,
          where: '${Keys.metconId} = ?', whereArgs: [id.toInt()]);
    });
  }

  DbResult<List<MetconMovement>> getByMetcon(Int64 id) async {
    return request<List<MetconMovement>>(() async {
      final result = await database.query(tableName,
          where: '${Keys.metconId} = ? AND ${Keys.deleted} = 0',
          whereArgs: [id.toInt()]);
      return Success(result.map(serde.fromDbRecord).toList());
    });
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
