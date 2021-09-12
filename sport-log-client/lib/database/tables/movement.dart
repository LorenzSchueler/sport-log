import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementTable extends Table<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  String get setupSql => '''
create table movement (
    user_id integer,
    name text not null,
    description text,
    category integer not null check (category in (0, 1)),
    $idAndDeletedAndStatus
);
  ''';

  @override
  String get tableName => 'movement';

  DbResult<List<Movement>> searchByName(String name) {
    return request(() async {
      final movements = await database.query(tableName,
          where: "name like '%$name%' and deleted = 0");
      return Success(movements.map((r) => serde.fromDbRecord(r)).toList());
    });
  }

  Future<bool> hasReference(Int64 id) async {
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

  DbResult<List<MovementDescription>> getNonDeletedFull() async {
    final result = await getNonDeleted();
    if (result.isFailure) {
      return Failure(result.failure);
    }
    final movements = result.success;
    return Success(await Future.wait(movements.map((movement) async {
      return MovementDescription(
        movement: movement,
        hasReference: await hasReference(movement.id),
      );
    }).toList()));
  }
}
