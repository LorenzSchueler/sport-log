
import 'dart:io';

import 'package:result_type/result_type.dart';
import 'package:sqflite/sqflite.dart';
import 'defs.dart';

export 'defs.dart';

abstract class Table<T extends DbObject> {
  String get setupSql;
  String get tableName;
  DbSerializer<T> get serde;

  late Database _db;

  Future<void> init(Database db) async {
    _db = db;
    await _db.execute(setupSql);
    await _db.execute('''
create trigger ${tableName}_last_change after update on $tableName
begin
  update $tableName set last_change = datetime('now') where id = new.id;
end;
    ''');
  }

  void _logError(Object error) {
    stderr.writeln(error);
  }

  DbResult<R> _request<R>(DbResult<R> Function(Database db) req) async {
    try {
      return await req(_db);
    } catch (e) {
      _logError(e);
      return Failure(DbError.unknown);
    }
  }

  DbResult<void> _voidRequest(Future<void> Function(Database db) req) async {
    return _request((db) async {
      await req(db);
      return Success(null);
    });
  }

  DbResult<void> unsafeDeleteSingle(T object) {
    assert(object.deleted == false);
    return _voidRequest((db) async {
      await _db.update(
          tableName,
          {"deleted": 1},
          where: "deleted = 0 AND id = ?",
          whereArgs: [object.id.toInt()]
      );
    });
  }

  DbResult<void> unsafeDeleteMultiple(List<T> objects) {
    assert(objects.every((element) => element.deleted == false));
    return _voidRequest((db) async {
      await _db.update(
        tableName,
        {"deleted": 1},
        where: "deleted = 0 AND id = ?",
        whereArgs: objects.map((e) => e.id.toInt()).toList(),
      );
    });
  }

  DbResult<void> unsafeUpdateSingle(T object) async {
    assert(object.isValid());
    return _voidRequest((db) async {
      await _db.update(
        tableName, serde.toDbRecord(object),
        where: "deleted = 0 AND id = ?",
        whereArgs: [object.id.toInt()],
      );
    });
  }

  DbResult<void> unsafeUpdateMultiple(List<T> objects) async {
    return _voidRequest((db) async {
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
    return _voidRequest((db) async {
      await _db.insert(tableName, {
        ...serde.toDbRecord(object),
        Keys.isNew: isNew ? 1 : 0,
      });
    });
  }

  DbResult<void> unsafeCreateMultiple(List<T> objects, bool isNew) async {
    return _voidRequest((db) async {
      final batch = _db.batch();
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
}
