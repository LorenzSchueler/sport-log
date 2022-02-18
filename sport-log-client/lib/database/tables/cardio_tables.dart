import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/cardio/all.dart';

class CardioSessionTable extends DbAccessor<CardioSession> {
  @override
  DbSerializer<CardioSession> get serde => DbCardioSessionSerializer();

  @override
  final Table table = Table(Tables.cardioSession, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.int(Keys.movementId)
        .references(Tables.movement, onDelete: OnAction.noAction),
    Column.int(Keys.cardioType).check("${Keys.cardioType} between 0 and 2"),
    Column.text(Keys.datetime),
    Column.int(Keys.distance).nullable().check("${Keys.distance} > 0"),
    Column.int(Keys.ascent).nullable().check("${Keys.ascent} >= 0"),
    Column.int(Keys.descent).nullable().check("${Keys.descent} >= 0"),
    Column.int(Keys.time).nullable().check("${Keys.time} > 0"),
    Column.int(Keys.calories).nullable().check("${Keys.calories} >= 0"),
    Column.blob(Keys.track).nullable(),
    Column.int(Keys.avgCadence).nullable().check("${Keys.avgCadence} > 0"),
    Column.blob(Keys.cadence).nullable(),
    Column.int(Keys.avgHeartRate).nullable().check("${Keys.avgHeartRate} > 0"),
    Column.blob(Keys.heartRate).nullable(),
    Column.int(Keys.routeId)
        .nullable()
        .references(Tables.route, onDelete: OnAction.setNull),
    Column.text(Keys.comments).nullable(),
  ]);
}

class RouteTable extends DbAccessor<Route> {
  @override
  DbSerializer<Route> get serde => DbRouteSerializer();

  @override
  final Table table = Table(Tables.route, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.text(Keys.name).check("length(${Keys.name}) >= 2"),
    Column.int(Keys.distance).check("${Keys.distance} > 0"),
    Column.int(Keys.ascent).nullable().check("${Keys.ascent} >= 0"),
    Column.int(Keys.descent).nullable().check("${Keys.descent} >= 0"),
    Column.blob(Keys.track)
  ]);
}
