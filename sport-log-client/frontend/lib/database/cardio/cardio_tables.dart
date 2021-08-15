
import 'package:moor/moor.dart';
import 'package:sport_log/helpers/db_serialization.dart';
import 'package:sport_log/models/cardio/all.dart';

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
  BlobColumn get track => blob().map()


  @override
  Set<Column>? get primaryKey => {id};
}