import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sqflite/sqflite.dart';

import 'defs.dart';

export 'defs.dart';

final _logger = Logger('DB');

abstract class Table<T extends DbObject> {
  String get setupSql;
  String get tableName;
  DbSerializer<T> get serde;

  late Database database;

  String get idAndDeletedAndStatus => '''
    id integer primary key,
    deleted integer not null default 0 check (deleted in (0, 1)),
    sync_status integer not null default 2 check (sync_status in (0, 1, 2))
  ''';

  @mustCallSuper
  Future<void> init(Database db) async {
    database = db;
    await database.execute(setupSql);
    await database.execute('''
create trigger ${tableName}_update after update on $tableName
begin
  update $tableName set sync_status = 1 where id = new.id and sync_status = 0;
end;
    ''');
  }

  DbResult<R> request<R>(DbResult<R> Function() req) async {
    try {
      return await req();
    } on DbError catch (e) {
      return Failure(e);
    } catch (e) {
      _logger.e(e.toString());
      return Failure(DbError.unknown);
    }
  }

  DbResult<void> voidRequest(Future<void> Function() req) async {
    return request(() async {
      await req();
      return Success(null);
    });
  }

  DbResult<void> deleteSingle(Int64 id, [Transaction? txn]) {
    return deleteMultiple([id], txn);
  }

  DbResult<void> deleteMultiple(List<Int64> ids, [Transaction? txn]) {
    return voidRequest(() async {
      await (txn ?? database).update(
        tableName,
        {"deleted": 1},
        where: "deleted = 0 AND id = ?",
        whereArgs: ids.map((id) => id.toInt()).toList(),
      );
    });
  }

  DbResult<void> updateSingle(T object, [Transaction? txn]) async {
    return updateMultiple([object], txn);
  }

  DbResult<void> updateMultiple(List<T> objects, [Transaction? txn]) async {
    return voidRequest(() async {
      final batch = (txn ?? database).batch();
      for (final object in objects) {
        assert(object.isValid());
        batch.update(
          tableName,
          serde.toDbRecord(object),
          where: "deleted = 0 AND id = ?",
          whereArgs: [object.id.toInt()],
        );
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }

  DbResult<void> createSingle(T object, [Transaction? txn]) async {
    return createMultiple([object], txn);
  }

  DbResult<void> createMultiple(List<T> objects, [Transaction? txn]) async {
    return voidRequest(() async {
      final batch = (txn ?? database).batch();
      for (final object in objects) {
        assert(object.isValid());
        batch.insert(tableName, serde.toDbRecord(object));
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }

  DbResult<List<T>> getNonDeleted([Transaction? txn]) async {
    return request(() async {
      final List<DbRecord> result =
          await (txn ?? database).query(tableName, where: 'deleted = 0');
      return Success(result.map(serde.fromDbRecord).toList());
    });
  }

  DbResult<List<T>> getWithSyncStatus(SyncStatus syncStatus) async {
    final int status = SyncStatus.values.indexOf(syncStatus);
    return request(() async {
      final List<DbRecord> result = await database.query(tableName,
          where: '${Keys.syncStatus} = $status');
      return Success(result.map(serde.fromDbRecord).toList());
    });
  }

  DbResult<List<T>> get({
    String? where,
    List<Object?>? whereArgs,
    Transaction? transaction,
  }) async {
    return request(() async {
      final List<DbRecord> result = await (transaction ?? database)
          .query(tableName, where: where, whereArgs: whereArgs);
      return Success(result.map(serde.fromDbRecord).toList());
    });
  }

  DbResult<T?> getSingle(
    Int64 id, {
    bool includeDeleted = false,
    Transaction? transaction,
  }) async {
    final filter = includeDeleted ? 'id = ?' : 'deleted = 0 and id = ?';
    return request(() async {
      final List<DbRecord> result = await (transaction ?? database)
          .query(tableName, where: filter, whereArgs: [id.toInt()]);
      if (result.isEmpty) {
        return Success(null);
      } else {
        assert(result.length == 1);
        return Success(serde.fromDbRecord(result.first));
      }
    });
  }

  DbResult<bool> exists(
    Int64 id, {
    bool includeDeleted = false,
    Transaction? transaction,
  }) async {
    return request(() async {
      final filter = includeDeleted ? 'id = ?' : 'deleted = 0 and id = ?';
      final List<DbRecord> result = await (transaction ?? database)
          .rawQuery("SELECT 1 FROM $tableName where $filter;", [id.toInt()]);
      return Success(result.isNotEmpty);
    });
  }

  DbResult<void> setSynchronized(Int64 id) async {
    return voidRequest(() async {
      database.update(tableName, {'sync_status': 0},
          where: 'id = ?', whereArgs: [id.toInt()]);
    });
  }

  DbResult<void> upsertMultiple(List<T> objects, [Transaction? txn]) async {
    return voidRequest(() async {
      final batch = (txn ?? database).batch();
      for (final object in objects) {
        assert(object.isValid());
        // TODO: what it sync_status == 1 or sync_status == 2?
        batch.insert(tableName, serde.toDbRecord(object),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }
}
