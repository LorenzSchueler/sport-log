
import 'dart:io';

import 'package:result_type/result_type.dart';
import 'package:sqflite/sqflite.dart';

import 'defs.dart';

abstract class Table<T extends DbObject> {
  String get createTable;
  String get tableName;
  DbSerializer<T> get serde;

  late final Database _db;

  Table(Database database) : _db = database;

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

  DbResult<void> _deleteSingle(T object) {
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

  DbResult<void> _deleteMultiple(List<T> objects) {
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

  DbResult<void> _updateSingle(T object) async {
    return _voidRequest((db) async {
      await _db.update(
        tableName, serde.toDbRecord(object),
        where: "deleted = 0 AND id = ?",
        whereArgs: [object.id.toInt()],
      );
    });
  }

  DbResult<void> _updateMultiple(List<T> objects) async {
    return _voidRequest((db) async {
      final batch = db.batch();
      for (final object in objects) {
        batch.update(
          tableName, serde.toDbRecord(object),
          where: "deleted = 0 AND id = ?",
          whereArgs: [object.id.toInt()],
        );
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }

  DbResult<void> _createSingle(T object) async {
    return _voidRequest((db) async {
      await _db.insert(tableName, serde.toDbRecord(object));
    });
  }

  DbResult<void> _createMultiple(List<T> objects) async {
    return _voidRequest((db) async {
      final batch = _db.batch();
      for (final object in objects) {
        batch.insert(tableName, serde.toDbRecord(object));
      }
      await batch.commit(noResult: true, continueOnError: true);
    });
  }
}
