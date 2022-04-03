import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/helpers/eorm.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/all.dart';

class StrengthSessionAndMovement {
  StrengthSessionAndMovement({
    required this.session,
    required this.movement,
  });
  StrengthSession session;
  Movement movement;
}

class StrengthSessionTable extends TableAccessor<StrengthSession> {
  @override
  DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();

  @override
  final Table table = Table(
    name: Tables.strengthSession,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.text(Columns.datetime),
      Column.int(Columns.movementId)
        ..references(Tables.movement, onDelete: OnAction.cascade),
      Column.int(Columns.interval)
        ..nullable()
        ..checkGt(0),
      Column.text(Columns.comments)..nullable(),
    ],
    uniqueColumns: [
      [Columns.datetime, Columns.movementId]
    ],
    rawSql: [
      '''
        create table ${Tables.eorm} (
          ${Columns.eormReps} integer primary key check (${Columns.eormReps} >= 1),
          ${Columns.eormPercentage} real not null check (${Columns.eormPercentage} > 0)
        );
        ''',
      '''
        insert into ${Tables.eorm} (${Columns.eormReps}, ${Columns.eormPercentage}) values $eormValuesSql;
        ''',
    ],
  );
}

class StrengthSetTable extends TableAccessor<StrengthSet> {
  @override
  DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();

  @override
  final Table table = Table(
    name: Tables.strengthSet,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.strengthSessionId)
        ..references(Tables.strengthSession, onDelete: OnAction.cascade),
      Column.int(Columns.setNumber)..checkGe(0),
      Column.int(Columns.count)..checkGe(1),
      Column.real(Columns.weight)
        ..nullable()
        ..checkGt(0),
    ],
    uniqueColumns: [
      [Columns.strengthSessionId, Columns.setNumber]
    ],
  );

  Future<List<StrengthSet>> getByStrengthSession(
    StrengthSession strengthSession,
  ) async {
    final result = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        '${Columns.strengthSessionId} = ?',
      ]),
      whereArgs: [strengthSession.id.toInt()],
      orderBy: Columns.setNumber,
    );
    return result.map(serde.fromDbRecord).toList();
  }
}

class StrengthSessionDescriptionTable {
  static const count = Columns.count;
  static const datetime = Columns.datetime;
  static const deleted = Columns.deleted;
  static const eormPercentage = Columns.eormPercentage;
  static const eormReps = Columns.eormReps;
  static const id = Columns.id;
  static const maxCount = Columns.maxCount;
  static const maxEorm = Columns.maxEorm;
  static const maxWeight = Columns.maxWeight;
  static const minCount = Columns.minCount;
  static const movementId = Columns.movementId;
  static const name = Columns.name;
  static const numSets = Columns.numSets;
  static const setNumber = Columns.setNumber;
  static const strengthSessionId = Columns.strengthSessionId;
  static const sumCount = Columns.sumCount;
  static const sumVolume = Columns.sumVolume;
  static const weight = Columns.weight;

  static StrengthSessionTable get _strengthSessionTable =>
      AppDatabase.strengthSessions;

  static MovementTable get _movementTable => AppDatabase.movements;
  static StrengthSetTable get _strengthSetTable => AppDatabase.strengthSets;

  Future<StrengthSessionDescription?> getById(Int64 idValue) async {
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${_strengthSessionTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM ${Tables.strengthSession}
        JOIN ${Tables.movement} ON ${Tables.movement}.$id = ${Tables.strengthSession}.$movementId
      WHERE ${Tables.strengthSession}.$deleted = 0
        AND ${Tables.movement}.$deleted = 0
        AND ${Tables.strengthSession}.$id = ?;
    ''',
      [idValue.toInt()],
    );
    if (records.isEmpty) {
      return null;
    }
    final strengthSession = _strengthSessionTable.serde.fromDbRecord(
      records.first,
      prefix: _strengthSessionTable.table.prefix,
    );
    return StrengthSessionDescription(
      session: strengthSession,
      movement: _movementTable.serde
          .fromDbRecord(records.first, prefix: _movementTable.table.prefix),
      sets: await _strengthSetTable.getByStrengthSession(strengthSession),
    );
  }

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovement({
    Movement? movementValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${_strengthSessionTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM ${Tables.strengthSession}
      JOIN ${Tables.movement} ON ${Tables.movement}.$id = ${Tables.strengthSession}.$movementId
      WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.movement),
            TableAccessor.notDeletedOfTable(Tables.strengthSession),
            TableAccessor.fromFilterOfTable(Tables.strengthSession, from),
            TableAccessor.untilFilterOfTable(Tables.strengthSession, until),
            TableAccessor.movementIdFilterOfTable(
              Tables.strengthSession,
              movementValue,
            ),
          ])}
      GROUP BY ${TableAccessor.groupByIdOfTable(Tables.strengthSession)}
      ORDER BY ${TableAccessor.orderByDatetimeOfTable(Tables.strengthSession)}
      ;
    ''',
    );
    List<StrengthSessionDescription> strengthSessionDescriptions = [];
    for (final Map<String, Object?> record in records) {
      final session = _strengthSessionTable.serde
          .fromDbRecord(record, prefix: _strengthSessionTable.table.prefix);
      strengthSessionDescriptions.add(
        StrengthSessionDescription(
          session: session,
          sets: await _strengthSetTable.getByStrengthSession(session),
          movement: _movementTable.serde
              .fromDbRecord(record, prefix: _movementTable.table.prefix),
        ),
      );
    }
    return strengthSessionDescriptions;
  }

  Future<List<StrengthSet>> getSetsOnDay({
    required DateTime date,
    required Int64 movementIdValue,
  }) async {
    final start = date.beginningOfDay();
    final end = date.endOfDay();
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${_strengthSetTable.table.allColumns}
      FROM ${Tables.strengthSession}
        JOIN ${Tables.strengthSet} ON ${Tables.strengthSet}.$strengthSessionId = ${Tables.strengthSession}.$id
      WHERE ${Tables.strengthSet}.$deleted = 0
        AND ${Tables.strengthSession}.$deleted = 0
        AND ${Tables.strengthSession}.$datetime >= ?
        AND ${Tables.strengthSession}.$datetime < ?
        AND ${Tables.strengthSession}.$movementId = ?
      ORDER BY ${Tables.strengthSession}.$datetime, ${Tables.strengthSession}.$id, ${Tables.strengthSet}.$setNumber;
    ''',
      [start.toString(), end.toString(), movementIdValue.toInt()],
    );
    return records.mapToList(
      (record) => _strengthSetTable.serde
          .fromDbRecord(record, prefix: _strengthSetTable.table.prefix),
    );
  }

  Future<List<StrengthSessionStats>> getStatsAggregationsByDay({
    required Int64 movementIdValue,
    required DateTime from,
    required DateTime until,
  }) async {
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${Tables.strengthSession}.$datetime AS [$datetime],
        date(${Tables.strengthSession}.$datetime) AS [date],
        COUNT(${Tables.strengthSet}.$id) AS $numSets,
        MIN(${Tables.strengthSet}.$count) AS $minCount,
        MAX(${Tables.strengthSet}.$count) AS $maxCount,
        SUM(${Tables.strengthSet}.$count) AS $sumCount,
        MAX(${Tables.strengthSet}.$weight) AS $maxWeight,
        SUM(${Tables.strengthSet}.$count * ${Tables.strengthSet}.$weight) AS $sumVolume,
        MAX(${Tables.strengthSet}.$weight / $eormPercentage) AS $maxEorm
      FROM ${Tables.strengthSession}
        JOIN ${Tables.strengthSet} ON ${Tables.strengthSet}.$strengthSessionId = ${Tables.strengthSession}.$id
        LEFT JOIN ${Tables.eorm} ON $eormReps = ${Tables.strengthSet}.$count
      WHERE ${Tables.strengthSet}.$deleted = 0
        AND ${Tables.strengthSession}.$deleted = 0
        AND ${Tables.strengthSession}.$movementId = ?
        AND ${Tables.strengthSession}.$datetime >= ?
        AND ${Tables.strengthSession}.$datetime < ?
      GROUP BY [date]
      ORDER BY [date];
     ''',
      [movementIdValue.toInt(), from.toString(), until.toString()],
    );
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }

  Future<List<StrengthSessionStats>> getStatsAggregationsByWeek({
    required Int64 movementIdValue,
    required DateTime from,
    required DateTime until,
  }) async {
    assert(
      from.year == until.year || from.beginningOfYear().yearLater() == until,
    );
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${Tables.strengthSession}.$datetime AS [$datetime],
        strftime('%W', ${Tables.strengthSession}.$datetime) AS week,
        COUNT(${Tables.strengthSet}.$id) AS $numSets,
        MIN(${Tables.strengthSet}.$count) AS $minCount,
        MAX(${Tables.strengthSet}.$count) AS $maxCount,
        SUM(${Tables.strengthSet}.$count) AS $sumCount,
        MAX(${Tables.strengthSet}.$weight) AS $maxWeight,
        SUM(${Tables.strengthSet}.$count * ${Tables.strengthSet}.$weight) AS $sumVolume,
        MAX(${Tables.strengthSet}.$weight / $eormPercentage) AS $maxEorm
      FROM ${Tables.strengthSession}
        JOIN ${Tables.strengthSet} ON ${Tables.strengthSet}.$strengthSessionId = ${Tables.strengthSession}.$id
        LEFT JOIN ${Tables.eorm} ON $eormReps = ${Tables.strengthSet}.$count
      WHERE ${Tables.strengthSet}.$deleted = 0
        AND ${Tables.strengthSession}.$deleted = 0
        AND ${Tables.strengthSession}.$movementId = ?
        AND ${Tables.strengthSession}.$datetime >= ?
        AND ${Tables.strengthSession}.$datetime < ?
      GROUP BY week
      ORDER BY week;
    ''',
      [movementIdValue.toInt(), from.toString(), until.toString()],
    );
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }

  Future<List<StrengthSessionStats>> getStatsAggregationsByMonth({
    required Int64 movementIdValue,
  }) async {
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${Tables.strengthSession}.$datetime AS [$datetime],
        strftime('%Y_%m', ${Tables.strengthSession}.$datetime) AS month,
        COUNT(${Tables.strengthSet}.$id) AS $numSets,
        MIN(${Tables.strengthSet}.$count) AS $minCount,
        MAX(${Tables.strengthSet}.$count) AS $maxCount,
        SUM(${Tables.strengthSet}.$count) AS $sumCount,
        MAX(${Tables.strengthSet}.$weight) AS $maxWeight,
        SUM(${Tables.strengthSet}.$count * ${Tables.strengthSet}.$weight) AS $sumVolume,
        MAX(${Tables.strengthSet}.$weight / $eormPercentage) AS $maxEorm
      FROM ${Tables.strengthSession}
        JOIN ${Tables.strengthSet} ON ${Tables.strengthSet}.$strengthSessionId = ${Tables.strengthSession}.$id
        LEFT JOIN ${Tables.eorm} ON $eormReps = ${Tables.strengthSet}.$count
      WHERE ${Tables.strengthSet}.$deleted = 0
        AND ${Tables.strengthSession}.$deleted = 0
        AND ${Tables.strengthSession}.$movementId = ?
      GROUP BY month
      ORDER BY month;
    ''',
      [movementIdValue.toInt()],
    );
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }
}
