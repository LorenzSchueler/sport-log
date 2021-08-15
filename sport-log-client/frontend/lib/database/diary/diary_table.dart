
import 'package:moor/moor.dart';
import 'package:sport_log/helpers/db_serialization.dart';
import 'package:sport_log/models/diary/diary.dart';

@UseRowClass(Diary)
class Diaries extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().map(const DbIdConverter())();
  DateTimeColumn get date => dateTime()();
  RealColumn get bodyweight => real().nullable()();
  TextColumn get comments => text().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}