import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/movement/movement.dart';

class RouteTable extends TableAccessor<Route> {
  factory RouteTable() => _instance;

  RouteTable._();

  static final _instance = RouteTable._();

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
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.int(Columns.distance)
        ..nullable()
        ..checkGt(0),
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
      [Columns.name],
    ],
  );

  @override
  Future<List<Route>> getNonDeleted() async {
    final records = await database.query(
      tableName,
      where: notDeleted,
      orderBy: orderByName,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class CardioSessionTable extends TableAccessor<CardioSession> {
  factory CardioSessionTable() => _instance;

  CardioSessionTable._();

  static final _instance = CardioSessionTable._();

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
    uniqueColumns: [],
  );

  Future<List<CardioSession>> getByMovementWithTrackOrderDatetime({
    Movement? movement,
  }) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter(
        [notDeleted, movementIdFilter(movement), withTrack],
      ),
      orderBy: orderByDatetime,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}

class CardioSessionDescriptionTable {
  factory CardioSessionDescriptionTable() => _instance;

  CardioSessionDescriptionTable._();

  static final _instance = CardioSessionDescriptionTable._();

  static final CardioSessionTable _cardioSessionTable = CardioSessionTable();
  static final RouteTable _routeTable = RouteTable();
  static final MovementTable _movementTable = MovementTable();

  Future<List<CardioSessionDescription>> getByTimerangeAndMovementAndComment({
    DateTime? from,
    DateTime? until,
    Movement? movement,
    String? comment,
  }) async {
    final records = await AppDatabase.database.rawQuery(
      '''
      SELECT
        ${_cardioSessionTable.table.allColumns},
        ${_routeTable.table.allColumns},
        ${_movementTable.table.allColumns}
      FROM ${Tables.cardioSession}
      LEFT JOIN ${Tables.route} 
      ON ${Tables.route}.${Columns.id} = ${Tables.cardioSession}.${Columns.routeId}
      JOIN ${Tables.movement} 
      ON ${Tables.movement}.${Columns.id} = ${Tables.cardioSession}.${Columns.movementId}
      WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.movement),
            "(${TableAccessor.notDeletedOfTable(Tables.route)} or ${Tables.route}.${Columns.deleted} is null)", // left join -> can be null
            TableAccessor.notDeletedOfTable(Tables.cardioSession),
            TableAccessor.fromFilterOfTable(Tables.cardioSession, from),
            TableAccessor.untilFilterOfTable(Tables.cardioSession, until),
            TableAccessor.movementIdFilterOfTable(
              Tables.cardioSession,
              movement,
            ),
            TableAccessor.commentFilterOfTable(Tables.cardioSession, comment),
          ])}
      ORDER BY ${TableAccessor.orderByDatetimeOfTable(Tables.cardioSession)}
      ''',
    );
    return records
        .map(
          (record) => CardioSessionDescription(
            cardioSession: _cardioSessionTable.serde
                .fromDbRecord(record, prefix: _cardioSessionTable.table.prefix),
            route: _routeTable.serde
                .fromOptionalDbRecord(record, prefix: _routeTable.table.prefix),
            movement: _movementTable.serde
                .fromDbRecord(record, prefix: _movementTable.table.prefix),
          ),
        )
        .toList();
  }
}
