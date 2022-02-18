import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/cardio/all.dart';

class CardioSessionTable extends TableAccessor<CardioSession> {
  @override
  DbSerializer<CardioSession> get serde => DbCardioSessionSerializer();

  @override
  final Table table = Table(Tables.cardioSession, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.int(Columns.movementId)
        .references(Tables.movement, onDelete: OnAction.noAction),
    Column.int(Columns.cardioType)
        .check("${Columns.cardioType} between 0 and 2"),
    Column.text(Columns.datetime),
    Column.int(Columns.distance).nullable().check("${Columns.distance} > 0"),
    Column.int(Columns.ascent).nullable().check("${Columns.ascent} >= 0"),
    Column.int(Columns.descent).nullable().check("${Columns.descent} >= 0"),
    Column.int(Columns.time).nullable().check("${Columns.time} > 0"),
    Column.int(Columns.calories).nullable().check("${Columns.calories} >= 0"),
    Column.blob(Columns.track).nullable(),
    Column.int(Columns.avgCadence)
        .nullable()
        .check("${Columns.avgCadence} > 0"),
    Column.blob(Columns.cadence).nullable(),
    Column.int(Columns.avgHeartRate)
        .nullable()
        .check("${Columns.avgHeartRate} > 0"),
    Column.blob(Columns.heartRate).nullable(),
    Column.int(Columns.routeId)
        .nullable()
        .references(Tables.route, onDelete: OnAction.setNull),
    Column.text(Columns.comments).nullable(),
  ]);
}

class RouteTable extends TableAccessor<Route> {
  @override
  DbSerializer<Route> get serde => DbRouteSerializer();

  @override
  final Table table = Table(Tables.route, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.text(Columns.name).check("length(${Columns.name}) >= 2"),
    Column.int(Columns.distance).check("${Columns.distance} > 0"),
    Column.int(Columns.ascent).nullable().check("${Columns.ascent} >= 0"),
    Column.int(Columns.descent).nullable().check("${Columns.descent} >= 0"),
    Column.blob(Columns.track)
  ]);
}
