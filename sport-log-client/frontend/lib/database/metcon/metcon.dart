
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/metcon/metcon.dart';

export 'package:sport_log/models/metcon/metcon.dart';

part 'metcon.g.dart';

class DbIdConverter extends TypeConverter<Int64, int> {
  const DbIdConverter() : super();

  @override
  Int64? mapToDart(int? fromDb) {
    return fromDb == null ? null : Int64(fromDb);
  }

  @override
  int? mapToSql(Int64? value) {
    return value?.toInt();
  }
}

@UseRowClass(Metcon)
class Metcons extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().nullable().map(const DbIdConverter())();
  TextColumn get name => text().nullable()();
  IntColumn get metconType => intEnum<MetconType>()();
  IntColumn get rounds => integer().nullable()();
  IntColumn get timecap => integer().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get deleted => boolean()();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}


@UseDao(tables: [Metcons])
class MetconsDao extends DatabaseAccessor<Database> with _$MetconsDaoMixin {
  MetconsDao(Database attachedDatabase) : super(attachedDatabase);

  Future<void> insertMetcon(Metcon metcon) async {
    assert(metcon.deleted == false);
    into(metcons).insert(metcon);
  }

  Future<List<Metcon>> getAllMetcons() async {
    return (select(metcons)
      ..where((m) => m.deleted.equals(false))
    ).get();
  }

  Future<void> updateMetcon(Metcon metcon) async {
    assert(metcon.deleted == false);
    (update(metcons)
      ..where((m) => m.id.equals(metcon.id.toInt()))
    ).write(metcon);
  }

  Future<void> setAllIsNewFalse() async {
    (update(metcons)
      ..where((m) => m.isNew.equals(true))
    ).write(const MetconsCompanion(isNew: Value(false)));
  }

  Future<void> deleteMetcon(Int64 id) async {
    (update(metcons)
        ..where((m) => m.id.equals(id.toInt()))
    ).write(const MetconsCompanion(deleted: Value(true)));
  }
}