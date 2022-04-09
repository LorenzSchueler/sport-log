import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/movement/movement.dart';

class RouteTable extends TableAccessor<Route> {
  @override
  DbSerializer<Route> get serde => DbRouteSerializer();

  @override
  final Table table = Table(
    name: Tables.route,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
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
    uniqueColumns: [
      [Columns.name]
    ],
  );

  @override
  Future<List<Route>> getNonDeleted() async {
    final result = await database.query(
      tableName,
      where: notDeleted,
      orderBy: orderByName,
    );
    return result.map(serde.fromDbRecord).toList();
  }

  Future<List<Route>> getByName(String? name) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        nameFilter(name),
      ]),
      orderBy: orderByName,
    );
    return records.map((r) => serde.fromDbRecord(r)).toList();
  }
}

class CardioSessionTable extends TableAccessor<CardioSession> {
  @override
  DbSerializer<CardioSession> get serde => DbCardioSessionSerializer();

  @override
  final Table table = Table(
    name: Tables.cardioSession,
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
    uniqueColumns: [
      [Columns.movementId, Columns.datetime]
    ],
  );
}

class CardioSessionDescriptionTable {
  static CardioSessionTable get _cardioSessionTable =>
      AppDatabase.cardioSessions;
  static RouteTable get _routeTable => AppDatabase.routes;
  static MovementTable get _movementTable => AppDatabase.movements;

  Future<List<CardioSessionDescription>> getByTimerangeAndMovement({
    Movement? movementValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${_cardioSessionTable.table.allColumns},
        ${_routeTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM ${Tables.cardioSession}
      LEFT JOIN (
        SELECT * FROM ${Tables.route} 
        WHERE ${Tables.route}.${Columns.deleted} = false
      ) AS ${Tables.route} ON ${Tables.route}.${Columns.id} = ${Tables.cardioSession}.${Columns.routeId}
      JOIN ${Tables.movement} ON ${Tables.movement}.${Columns.id} = ${Tables.cardioSession}.${Columns.movementId}
      WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.movement),
            TableAccessor.notDeletedOfTable(Tables.cardioSession),
            TableAccessor.fromFilterOfTable(Tables.cardioSession, from),
            TableAccessor.untilFilterOfTable(Tables.cardioSession, until),
            TableAccessor.movementIdFilterOfTable(
              Tables.cardioSession,
              movementValue,
            ),
          ])}
      GROUP BY ${TableAccessor.groupByIdOfTable(Tables.cardioSession)}
      ORDER BY ${TableAccessor.orderByDatetimeOfTable(Tables.cardioSession)}
    ''',
    );
    List<CardioSessionDescription> cardioSessionDescriptions = [];
    for (final Map<String, Object?> record in records) {
      cardioSessionDescriptions.add(
        CardioSessionDescription(
          cardioSession: _cardioSessionTable.serde
              .fromDbRecord(record, prefix: _cardioSessionTable.table.prefix),
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
