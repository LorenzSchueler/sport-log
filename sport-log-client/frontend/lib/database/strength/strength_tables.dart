
import 'package:moor/moor.dart';
import 'package:sport_log/helpers/db_serialization.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/all.dart';

@UseRowClass(StrengthSession)
class StrengthSessions extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().map(const DbIdConverter())();
  DateTimeColumn get datetime => dateTime()();
  IntColumn get movementId => integer().map(const DbIdConverter())();
  IntColumn get movementUnit => intEnum<MovementUnit>()();
  IntColumn get interval => integer().nullable()();
  TextColumn get comments => text().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}

@UseRowClass(StrengthSet)
class StrengthSets extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get strengthSessionId => integer().map(const DbIdConverter())();
  IntColumn get setNumber => integer()();
  IntColumn get count => integer()();
  RealColumn get weight => real().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}