import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementTable extends DbAccessor<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  String get setupSql => _table.setupSql();

  final Table _table = Table(Tables.movement, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId).nullable(),
    Column.text(Keys.name),
    Column.text(Keys.description).nullable(),
    Column.bool(Keys.cardio),
    Column.int(Keys.unit),
  ]);

  static const deleted = Keys.deleted;
  static const unit = Keys.unit;
  static const name = Keys.name;
  static const userId = Keys.userId;
  static const id = Keys.id;

  @override
  String get tableName => _table.name;

  Table get table => _table;

  Future<bool> hasReference(Int64 id) async {
    // TODO: this is awkward, maybe with sql
    final metconMovements = AppDatabase.instance!.metconMovements.tableName;
    final strengthSessions = AppDatabase.instance!.strengthSessions.tableName;
    final cardioSessions = AppDatabase.instance!.cardioSessions.tableName;
    final s1 = await database.rawQuery(
        'select 1 from $metconMovements where ${Keys.deleted} = 0 and ${Keys.movementId} = ${id.toInt()}');
    if (s1.isNotEmpty) {
      return true;
    }
    final s2 = await database.rawQuery(
        'select 1 from $strengthSessions where ${Keys.deleted} = 0 and ${Keys.movementId} = ${id.toInt()}');
    if (s2.isNotEmpty) {
      return true;
    }
    final s3 = await database.rawQuery(
        'select 1 from $cardioSessions where ${Keys.deleted} = 0 and ${Keys.movementId} = ${id.toInt()}');
    if (s3.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<List<MovementDescription>> getNonDeletedFull() async {
    final result = await getNonDeleted();
    return Future.wait(result.map((movement) async {
      return MovementDescription(
        movement: movement,
        hasReference: await hasReference(movement.id),
      );
    }).toList());
  }

  Future<List<Movement>> getMovements({
    String? byName,
  }) async {
    final nameFilter = byName != null ? '$name LIKE ?' : '1 = 1';
    final records = await database.rawQuery('''
      SELECT * FROM $tableName m1
      WHERE $deleted = 0
        AND $nameFilter
        AND ($userId IS NOT NULL
          OR NOT EXISTS (
            SELECT * FROM $tableName m2
            WHERE m1.$id <> m2.$id
              AND m1.$name = m2.$name
              AND m1.$unit = m2.$unit
              AND m2.$userId IS NOT NULL
          )
        )
      ORDER BY $name
    ''', [if (byName != null) '%$byName%']);
    return records.map((r) => serde.fromDbRecord(r)).toList();
  }
}
