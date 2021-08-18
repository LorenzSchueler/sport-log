
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sqflite/sqflite.dart';
import 'defs.dart';

export 'defs.dart';

abstract class Table<T extends DbObject> {
  String get setupSql;
  String get tableName;
  DbSerializer<T> get serde;

  late Database database;

  Future<void> init(Database db) async {
    database = db;
    await database.execute(setupSql);
    await database.execute('''
create trigger ${tableName}_last_change after update on $tableName
begin
  update $tableName set last_change = datetime('now') where id = new.id;
end;
    ''');
  }

  void logError(Object error) {
    stderr.writeln(error);
  }

  DbResult<R> request<R>(DbResult<R> Function(Database db) req) async {
    try {
      return await req(database);
    } catch (e) {
      logError(e);
      return Failure(DbError.unknown);
    }
  }

  DbResult<void> voidRequest(Future<void> Function(Database db) req) async {
    return request((db) async {
      await req(db);
      return Success(null);
    });
  }

  DbResult<void> unsafeDeleteSingle(Int64 id) {
    return voidRequest((db) async {
      await database.update(
          tableName,
          {"deleted": 1},
          where: "deleted = 0 AND id = ?",
          whereArgs: [id.toInt()]
      );
    });
  }

  DbResult<void> unsafeDeleteMultiple(List<Int64> ids) {
    return voidRequest((db) async {
      await database.update(
        tableName,
        {"deleted": 1},
        where: "deleted = 0 AND id = ?",
        whereArgs: ids.map((id) => id.toInt()).toList(),
      );
    });
  }

  DbResult<void> unsafeUpdateSingle(T object) async {
    assert(object.isValid());
    return voidRequest((db) async {
      await database.update(
        tableName, serde.toDbRecord(object),
        where: "deleted = 0 AND id = ?",
        whereArgs: [object.id.toInt()],
      );
    });
  }

  DbResult<void> unsafeUpdateMultiple(List<T> objects) async {
    return voidRequest((db) async {
      final batch = db.batch();
      for (final object in objects) {
        assert(object.isValid());
        batch.update(
          tableName, serde.toDbRecord(object),
          where: "deleted = 0 AND id = ?",
          whereArgs: [object.id.toInt()],
        );
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }

  DbResult<void> unsafeCreateSingle(T object, bool isNew) async {
    assert(object.isValid());
    return voidRequest((db) async {
      await database.insert(tableName, {
        ...serde.toDbRecord(object),
        Keys.isNew: isNew ? 1 : 0,
      });
    });
  }

  DbResult<void> unsafeCreateMultiple(List<T> objects, bool isNew) async {
    return voidRequest((db) async {
      final batch = database.batch();
      for (final object in objects) {
        assert(object.isValid());
        batch.insert(tableName, {
          ...serde.toDbRecord(object),
          Keys.isNew: isNew ? 1 : 0,
        });
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }

  DbResult<List<T>> getAll({
    bool onlyIsNew = false,
    bool includeDeleted = false,
  }) async {
    return request((db) async {
      final filter = onlyIsNew
          ? (includeDeleted ? "is_new = 1" : "is_new = 1 and deleted = 0")
          : (includeDeleted ? null : "deleted = 0");
      final List<DbRecord> result = await db.query(tableName, where: filter);
      return Success(result.map(serde.fromDbRecord).toList());
    });
  }

  DbResult<void> setAllIsNewFalse() async {
    return voidRequest((db) async {
      await db.update(tableName, {"is_new": 0}, where: "is_new = 1");
    });
  }
}
