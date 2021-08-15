
import 'package:moor/moor.dart';
import 'package:sport_log/helpers/db_serialization.dart';
import 'package:sport_log/models/cardio/all.dart';

@UseRowClass(CardioSession)
class CardioSessions extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().map(const DbIdConverter())();
  IntColumn get movementId => integer().map(const DbIdConverter())();
  IntColumn get cardioType => intEnum<CardioType>()();
  DateTimeColumn get datetime => dateTime()();
  IntColumn get distance => integer().nullable()();
  IntColumn get ascent => integer().nullable()();
  IntColumn get descent => integer().nullable()();
  IntColumn get time => integer().nullable()();
  IntColumn get calories => integer().nullable()();
  BlobColumn get track => blob().nullable().map(const DbPositionListConverter())();
  IntColumn get avgCycles => integer().nullable()();
  BlobColumn get cycles => blob().nullable().map(const DbDoubleListConverter())();
  IntColumn get avgHeartRate => integer().nullable()();
  BlobColumn get heartRate => blob().nullable().map(const DbDoubleListConverter())();
  IntColumn get routeId => integer().nullable().map(const DbIdConverter())();
  TextColumn get comments => text().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}

@UseRowClass(Route)
class Routes extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().map(const DbIdConverter())();
  TextColumn get name => text()();
  IntColumn get distance => integer()();
  IntColumn get ascent => integer().nullable()();
  IntColumn get descent => integer().nullable()();
  BlobColumn get track => blob().nullable().map(const DbPositionListConverter())();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}