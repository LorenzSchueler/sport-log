
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_serialization.dart';
import 'package:sport_log/models/metcon/metcon_session.dart';

export 'package:sport_log/models/metcon/metcon_session.dart';

part 'metcon_sessions.g.dart';

@UseRowClass(MetconSession)
class MetconSessions extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get userId => integer().map(const DbIdConverter())();
  IntColumn get metconId => integer().map(const DbIdConverter())();
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

@UseDao(tables: [MetconSessions])
class MetconSessionsDao extends DatabaseAccessor<Database> with _$MetconSessionsDaoMixin {
  MetconSessionsDao(Database attachedDatabase) : super(attachedDatabase);

  Future<void> insertMetconSession(MetconSession metconSession) async {
    assert(metconSession.deleted == false);
    into(metconSessions).insert(metconSession);
  }

  Future<List<MetconSession>> getAllMetconsSession() async {
    return (select(metconSessions)
      ..where((ms) => ms.deleted.equals(false))
    ).get();
  }

  Future<void> updateMetconMovement(MetconSession metconSession) async {
    assert(metconSession.deleted == false);
    (update(metconSessions)
      ..where((ms) => ms.id.equals(metconSession.id.toInt()))
    ).write(metconSession);
  }

  Future<void> setAllIsNewFalse() async {
    (update(metconSessions)
      ..where((ms) => ms.isNew.equals(true))
    ).write(const MetconSessionsCompanion(isNew: Value(false)));
  }

  Future<void> deleteMetconSession(Int64 id) async {
    (update(metconSessions)
      ..where((ms) => ms.id.equals(id.toInt()))
    ).write(const MetconSessionsCompanion(deleted: Value(true)));
  }
}