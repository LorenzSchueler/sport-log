import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';

class CardioSessionTable extends TableAccessor<CardioSession> {
  @override
  DbSerializer<CardioSession> get serde => DbCardioSessionSerializer();

  @override
  final Table table = Table(
    Tables.cardioSession,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.int(Columns.movementId)
        ..references(Tables.movement, onDelete: OnAction.noAction),
      Column.int(Columns.cardioType)..checkIn(<int>[0, 1, 2]),
      Column.text(Columns.datetime),
      Column.int(Columns.distance)
        ..nullable()
        ..checkGt(0),
      Column.int(Columns.ascent)
        ..nullable()
        ..checkGe(0),
      Column.int(Columns.descent)
        ..nullable()
        ..checkGe(0),
      Column.int(Columns.time)
        ..nullable()
        ..checkGt(0),
      Column.int(Columns.calories)
        ..nullable()
        ..checkGe(0),
      Column.blob(Columns.track)..nullable(),
      Column.int(Columns.avgCadence)
        ..nullable()
        ..checkGt(0),
      Column.blob(Columns.cadence)..nullable(),
      Column.int(Columns.avgHeartRate)
        ..nullable()
        ..checkGt(0),
      Column.blob(Columns.heartRate)..nullable(),
      Column.int(Columns.routeId)
        ..nullable()
        ..references(Tables.route, onDelete: OnAction.setNull),
      Column.text(Columns.comments)..nullable(),
    ],
  );

  static const datetime = Columns.datetime;
  static const deleted = Columns.deleted;
  static const id = Columns.id;
  static const routeId = Columns.routeId;
  static const movementId = Columns.movementId;

  static const route = Tables.route;
  static const movement = Tables.movement;

  static RouteTable get _routeTable => AppDatabase.routes;
  static MovementTable get _movementTable => AppDatabase.movements;

  Future<List<CardioSessionDescription>> getByTimerangeAndMovement({
    Int64? movementIdValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await database.rawQuery('''
      SELECT
        ${table.allColumns},
        ${_routeTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM $tableName
      LEFT JOIN 
        (SELECT * FROM $route WHERE $route.$deleted = false) AS $route ON $route.$id = $tableName.$routeId
      JOIN $movement ON $movement.$id = $tableName.$movementId
      WHERE $movement.$deleted = 0
        AND $tableName.$deleted = 0
        ${fromFilter(from)}
        ${untilFilter(until)}
        ${movementIdFilter(movementIdValue)}
      $groupById
      $orderByDatetime
      ;
    ''', [
      if (from != null) from.toString(),
      if (until != null) until.toString(),
      if (movementIdValue != null) movementIdValue.toInt(),
    ]);
    List<CardioSessionDescription> cardioSessionDescriptions = [];
    for (Map<String, Object?> record in records) {
      cardioSessionDescriptions.add(
        CardioSessionDescription(
          cardioSession: serde.fromDbRecord(record, prefix: table.prefix),
          route: _routeTable.serde
              .fromOptionalDbRecord(record, prefix: _routeTable.table.prefix),
          movement: _movementTable.serde
              .fromDbRecord(record, prefix: _movementTable.table.prefix),
        ),
      );
    }
    return cardioSessionDescriptions;
  }
}

class RouteTable extends TableAccessor<Route> {
  @override
  DbSerializer<Route> get serde => DbRouteSerializer();

  @override
  final Table table = Table(
    Tables.route,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.text(Columns.name)..checkLengthGe(2),
      Column.int(Columns.distance)..checkGt(0),
      Column.int(Columns.ascent)
        ..nullable()
        ..checkGe(0),
      Column.int(Columns.descent)
        ..nullable()
        ..checkGe(0),
      Column.blob(Columns.track)..nullable(),
      Column.blob(Columns.markedPositions)..nullable(),
    ],
  );

  @override
  Future<List<Route>> getNonDeleted() async {
    final result = await database.query(
      tableName,
      where: notDeleted,
      orderBy: "$tableName.${Columns.name} COLLATE NOCASE",
    );
    return result.map(serde.fromDbRecord).toList();
  }
}
