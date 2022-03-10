import 'package:collection/collection.dart';

import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sqflite/sqflite.dart';

export 'db_interfaces.dart';

bool Function(List<int> l1, List<int> l2) eq = const ListEquality<int>().equals;

abstract class TableAccessor<T extends AtomicEntity> {
  DbSerializer<T> get serde;
  Table get table;

  List<String> get setupSql => [table.setupSql(), updateTrigger];

  String get tableName => table.name;

  Database get database {
    return AppDatabase.database!;
  }

  String get idAndDeletedAndStatus => '''
    id integer primary key,
    deleted integer not null default 0 check (deleted in (0, 1)),
    sync_status integer not null default 2 check (sync_status in (0, 1, 2))
  ''';

  String get updateTrigger => '''
    create trigger ${tableName}_update before update on $tableName
    begin
      update $tableName set sync_status = 1 where id = new.id and sync_status = 0;
    end;
  ''';

  String get notDeleted => '${Columns.deleted} = 0';
  String fromFilter(DateTime? from) =>
      from == null ? '' : 'AND $tableName.${Columns.datetime} >= ?';
  String untilFilter(DateTime? until) =>
      until == null ? '' : 'AND $tableName.${Columns.datetime} < ?';
  String movementIdFilter(Int64? movementId) =>
      movementId == null ? '' : 'AND $tableName.${Columns.movementId} = ?';
  String get groupById => "GROUP BY $tableName.${Columns.id}";
  String get orderByDatetime =>
      "ORDER BY datetime($tableName.${Columns.datetime}) DESC";

  Future<bool> deleteSingle(Int64 id, {bool isSynchronized = false}) async {
    final changes = await database.update(
      tableName,
      {
        Columns.deleted: 1,
        if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
      },
      where: '${Columns.deleted} = 0 AND ${Columns.id} = ?',
      whereArgs: [id.toInt()],
    );
    return changes == 1;
  }

  Future<bool> deleteMultiple(
    List<T> objects, {
    bool isSynchronized = false,
  }) async {
    final batch = database.batch();
    for (final object in objects) {
      batch.update(
        tableName,
        {
          Columns.deleted: 1,
          if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
        },
        where: '${Columns.deleted} = 0 AND ${Columns.id} = ?',
        whereArgs: [object.id.toInt()],
      );
    }
    final changesList =
        (await batch.commit(continueOnError: false)).cast<int>();
    return eq(changesList, List.filled(objects.length, 1));
  }

  Future<bool> updateSingle(T object, {bool isSynchronized = false}) async {
    final changes = await database.update(
      tableName,
      {
        ...serde.toDbRecord(object),
        if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index
      },
      where: '${Columns.deleted} = 0 AND ${Columns.id} = ?',
      whereArgs: [object.id.toInt()],
    );
    return changes == 1;
  }

  Future<bool> updateMultiple(
    List<T> objects, {
    bool isSynchronized = false,
  }) async {
    final batch = database.batch();
    for (final object in objects) {
      batch.update(
        tableName,
        {
          ...serde.toDbRecord(object),
          if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index
        },
        where: '${Columns.deleted} = 0 AND ${Columns.id} = ?',
        whereArgs: [object.id.toInt()],
      );
    }
    final changesList =
        (await batch.commit(continueOnError: false)).cast<int>();
    return eq(changesList, List.filled(objects.length, 1));
  }

  Future<bool> createSingle(T object, {bool isSynchronized = false}) async {
    final id = await database.insert(tableName, {
      ...serde.toDbRecord(object),
      if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
    });
    return id == object.id.toInt();
  }

  Future<bool> createMultiple(
    List<T> objects, {
    bool isSynchronized = false,
  }) async {
    final batch = database.batch();
    for (final object in objects) {
      batch.insert(tableName, {
        ...serde.toDbRecord(object),
        if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
      });
    }
    final idList = (await batch.commit(continueOnError: false)).cast<int>();
    return eq(idList, objects.map((e) => e.id.toInt()).toList());
  }

  Future<List<T>> getNonDeleted() async {
    final result = await database.query(tableName, where: notDeleted);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<List<T>> getWithSyncStatus(SyncStatus syncStatus) async {
    final result = await database.query(
      tableName,
      where: '${Columns.syncStatus} = ?',
      whereArgs: [syncStatus.index],
    );
    return result.map(serde.fromDbRecord).toList();
  }

  Future<T?> getSingle(Int64 id) async {
    final result = await database
        .query(tableName, where: "${Columns.id} = ?", whereArgs: [id.toInt()]);
    return result.isEmpty ? null : serde.fromDbRecord(result.first);
  }

  static final synchronized = {
    Columns.syncStatus: SyncStatus.synchronized.index
  };

  Future<void> setSynchronized(Int64 id) async {
    await database.update(
      tableName,
      synchronized,
      where: '${Columns.id} = ?',
      whereArgs: [id.toInt()],
    );
  }

  Future<void> setAllUpdatedSynchronized() async {
    await database.update(
      tableName,
      synchronized,
      where: '${Columns.syncStatus} = ${SyncStatus.updated.index}',
    );
  }

  Future<void> setAllCreatedSynchronized() async {
    await database.update(
      tableName,
      synchronized,
      where: '${Columns.syncStatus} = ${SyncStatus.created.index}',
    );
  }

  Future<bool> upsertMultiple(
    List<T> objects, {
    required bool synchronized,
  }) async {
    final batch = database.batch();
    for (final object in objects) {
      // TODO: what it sync_status == 1 or sync_status == 2?
      batch.insert(
        tableName,
        {
          ...serde.toDbRecord(object),
          if (synchronized) Columns.syncStatus: SyncStatus.synchronized.index,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    final idList = (await batch.commit(continueOnError: false)).cast<int>();
    return eq(idList, objects.map((e) => e.id.toInt()).toList());
  }
}
