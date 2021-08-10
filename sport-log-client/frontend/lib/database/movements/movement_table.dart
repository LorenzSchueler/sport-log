
import 'package:moor/moor.dart';
import 'package:sport_log/helpers/id_serialization.dart';
import 'package:sport_log/models/movement/all.dart';

@UseRowClass(Movement)
class Movements extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().nullable().map(const DbIdConverter())();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get category => intEnum<MovementCategory>()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}