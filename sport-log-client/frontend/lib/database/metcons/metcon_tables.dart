
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/helpers/db_serialization.dart';

import 'package:moor/moor.dart';

@UseRowClass(Metcon)
class Metcons extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().nullable().map(const DbIdConverter())();
  TextColumn get name => text().nullable()();
  IntColumn get metconType => intEnum<MetconType>()();
  IntColumn get rounds => integer().nullable()();
  IntColumn get timecap => integer().nullable()();
  TextColumn get description => text().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}

@UseRowClass(MetconMovement)
class MetconMovements extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get metconId => integer().map(const DbIdConverter()).customConstraint("NOT NULL REFERENCES metcons(id)")();
  IntColumn get movementId => integer().map(const DbIdConverter())(); // TODO: foreign key
  IntColumn get movementNumber => integer()();
  IntColumn get count => integer()();
  IntColumn get unit => intEnum<MovementUnit>()();
  RealColumn get weight => real().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}

@UseRowClass(MetconSession)
class MetconSessions extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().map(const DbIdConverter())();
  IntColumn get metconId => integer().map(const DbIdConverter()).customConstraint("NOT NULL REFERENCES metcons(id)")();
  DateTimeColumn get datetime => dateTime()();
  IntColumn get time => integer().nullable()();
  IntColumn get rounds => integer().nullable()();
  IntColumn get reps => integer().nullable()();
  BoolColumn get rx => boolean()();
  TextColumn get comments => text().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}
