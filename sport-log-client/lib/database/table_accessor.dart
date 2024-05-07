import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sqflite/sqflite.dart';

export 'db_interfaces.dart';

bool Function(List<int> l1, List<int> l2) eq = const ListEquality<int>().equals;

abstract class TableAccessor<T extends AtomicEntity> {
  final _logger = Logger('Table');

  DbSerializer<T> get serde;
  Table get table;

  String get tableName => table.name;

  Database get database => AppDatabase.database;

  static String combineFilter(List<String> filter) {
    return filter.where((element) => element.isNotEmpty).join(" and ");
  }

  static String notDeletedOfTable(String tableName) =>
      '$tableName.${Columns.deleted} = 0';
  String get notDeleted => notDeletedOfTable(tableName);

  static String cardioOnlyOfTable(bool cardioOnly) =>
      cardioOnly ? '${Tables.movement}.${Columns.cardio} = 1' : '';

  static String distanceOnlyOfTable(bool distanceOnly) => distanceOnly
      ? "${Tables.movement}.${Columns.dimension} = ${MovementDimension.distance.index}"
      : '';

  static String fromFilterOfTable(
    String tableName,
    DateTime? from, {
    bool dateOnly = false,
  }) {
    if (from == null) {
      return "";
    } else if (dateOnly) {
      return "$tableName.${Columns.date} >= '${from.yearMonthDay}'";
    } else {
      return "$tableName.${Columns.datetime} >= '$from'";
    }
  }

  String fromFilter(DateTime? from, {bool dateOnly = false}) =>
      fromFilterOfTable(tableName, from, dateOnly: dateOnly);

  static String untilFilterOfTable(
    String tableName,
    DateTime? until, {
    bool dateOnly = false,
  }) {
    if (until == null) {
      return "";
    } else if (dateOnly) {
      return "$tableName.${Columns.date} < '${until.yearMonthDay}'";
    } else {
      return "$tableName.${Columns.datetime} < '$until'";
    }
  }

  String untilFilter(
    DateTime? until, {
    bool dateOnly = false,
  }) =>
      untilFilterOfTable(tableName, until, dateOnly: dateOnly);

  static String movementIdFilterOfTable(String tableName, Movement? movement) =>
      movement == null
          ? ''
          : '$tableName.${Columns.movementId} = ${movement.id}';
  String movementIdFilter(Movement? movement) =>
      movementIdFilterOfTable(tableName, movement);

  static String commentFilterOfTable(String tableName, String? comment) =>
      comment == null || comment.isEmpty
          ? ''
          : "$tableName.${Columns.comments} like '%$comment%'";
  String commentFilter(String? comment) =>
      commentFilterOfTable(tableName, comment);

  static String descriptionFilterOfTable(
    String tableName,
    String? description,
  ) =>
      description == null || description.isEmpty
          ? ''
          : "$tableName.${Columns.description} like '%$description%'";
  String descriptionFilter(String? description) =>
      descriptionFilterOfTable(tableName, description);

  static String withTrackOfTable(String tableName) =>
      "$tableName.${Columns.track} is not null";
  String get withTrack => withTrackOfTable(tableName);

  static String orderByDatetimeOfTable(String tableName) =>
      "$tableName.${Columns.datetime} desc";
  String get orderByDatetime => orderByDatetimeOfTable(tableName);

  static String orderByDatetimeOfTableAsc(String tableName) =>
      "$tableName.${Columns.datetime} asc";
  String get orderByDatetimeAsc => orderByDatetimeOfTableAsc(tableName);

  static String orderByDateOfTable(String tableName) =>
      "$tableName.${Columns.date} desc";
  String get orderByDate => orderByDateOfTable(tableName);

  static String orderByNameOfTable(String tableName) =>
      "$tableName.${Columns.name} collate nocase";
  String get orderByName => orderByNameOfTable(tableName);

  Future<void> setup() async {
    _logger.d("creating table: $tableName");
    for (final statement in table.setupSql) {
      if (Config.instance.outputDbStatement) {
        _logger.t(statement);
      }
      await database.execute(statement);
    }
  }

  Future<bool> hardDeleteSingle(Int64 id) async {
    final changes = await database.delete(
      tableName,
      where: '${Columns.id} = ?',
      whereArgs: [id.toInt()],
    );
    return changes == 1;
  }

  Future<DbResult> deleteSingle(Int64 id, {bool isSynchronized = false}) async {
    return DbResultExt.catchError(() async {
      final changes = await database.update(
        tableName,
        {
          Columns.deleted: 1,
          if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
        },
        where: combineFilter([
          notDeleted,
          '${Columns.id} = ?',
        ]),
        whereArgs: [id.toInt()],
      );
      return DbResultExt.fromBool(changes == 1);
    });
  }

  Future<DbResult> deleteMultiple(
    List<T> objects, {
    bool isSynchronized = false,
  }) async {
    return DbResultExt.catchError(() async {
      final batch = database.batch();
      for (final object in objects) {
        batch.update(
          tableName,
          {
            Columns.deleted: 1,
            if (isSynchronized)
              Columns.syncStatus: SyncStatus.synchronized.index,
          },
          where: combineFilter([
            notDeleted,
            '${Columns.id} = ?',
          ]),
          whereArgs: [object.id.toInt()],
        );
      }
      final changesList =
          (await batch.commit(continueOnError: false)).cast<int>();
      return DbResultExt.fromBool(
        eq(changesList, List.filled(objects.length, 1)),
      );
    });
  }

  Future<DbResult> updateSingle(T object, {bool isSynchronized = false}) async {
    return DbResultExt.catchError(() async {
      final changes = await database.update(
        tableName,
        {
          ...serde.toDbRecord(object),
          if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
        },
        where: combineFilter([
          notDeleted,
          '${Columns.id} = ?',
        ]),
        whereArgs: [object.id.toInt()],
      );
      return DbResultExt.fromBool(changes == 1);
    });
  }

  Future<DbResult> updateMultiple(
    List<T> objects, {
    bool isSynchronized = false,
  }) async {
    return DbResultExt.catchError(() async {
      final batch = database.batch();
      for (final object in objects) {
        batch.update(
          tableName,
          {
            ...serde.toDbRecord(object),
            if (isSynchronized)
              Columns.syncStatus: SyncStatus.synchronized.index,
          },
          where: combineFilter([
            notDeleted,
            '${Columns.id} = ?',
          ]),
          whereArgs: [object.id.toInt()],
        );
      }
      final changesList =
          (await batch.commit(continueOnError: false)).cast<int>();
      return DbResultExt.fromBool(
        eq(changesList, List.filled(objects.length, 1)),
      );
    });
  }

  Future<DbResult> createSingle(T object, {bool isSynchronized = false}) async {
    return DbResultExt.catchError(() async {
      final id = await database.insert(tableName, {
        ...serde.toDbRecord(object),
        if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
      });
      return DbResultExt.fromBool(id == object.id.toInt());
    });
  }

  Future<DbResult> createMultiple(
    List<T> objects, {
    bool isSynchronized = false,
  }) async {
    return DbResultExt.catchError(() async {
      final batch = database.batch();
      for (final object in objects) {
        batch.insert(tableName, {
          ...serde.toDbRecord(object),
          if (isSynchronized) Columns.syncStatus: SyncStatus.synchronized.index,
        });
      }
      final idList = (await batch.commit(continueOnError: false)).cast<int>();
      return DbResultExt.fromBool(
        eq(idList, objects.map((e) => e.id.toInt()).toList()),
      );
    });
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

  Future<T?> getById(Int64 id) async {
    final result = await database
        .query(tableName, where: "${Columns.id} = ?", whereArgs: [id.toInt()]);
    return result.isEmpty ? null : serde.fromDbRecord(result.first);
  }

  static final synchronized = {
    Columns.syncStatus: SyncStatus.synchronized.index,
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

  Future<DbResult> upsertMultiple(
    List<T> objects, {
    required bool synchronized,
  }) async {
    return DbResultExt.catchError(() async {
      final batch = database.batch();
      for (final object in objects) {
        // changes coming from server win over local changes
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
      return DbResultExt.fromBool(
        eq(idList, objects.map((e) => e.id.toInt()).toList()),
      );
    });
  }
}
