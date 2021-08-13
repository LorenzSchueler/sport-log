
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/movements/movement_table.dart';
import 'package:sport_log/models/movement/all.dart';

part 'movements_dao.g.dart';

@UseDao(
  tables: [Movements],
  include: {'movements.moor'}
)
class MovementsDao extends DatabaseAccessor<Database> with _$MovementsDaoMixin {
  MovementsDao(Database attachedDatabase) : super(attachedDatabase);

  Future<bool> movementExists(Int64 id) async {
    return await _movementExists(id.toInt()).getSingleOrNull() != null;
  }

  Future<List<MovementDescription>> getAllMovements() async {
    final List<Movement> movementList = await (select(movements)
      ..where((m) => m.deleted.equals(false))
    ).get();
    return Future.wait(movementList.map((m) async {
      return MovementDescription(
          movement: m,
          isDeletable: !(await movementHasDependency(m.id)),
      );
    }));
  }

  Future<bool> movementHasDependency(Int64 id) async {
    // TODO: check if there are no strength sessions or cardio sessions
    return await attachedDatabase.metconsDao
        .metconMovementWithMovementExists(id);
  }

  Future<Result<void, DbException>> deleteMovement(Int64 id) async {
    if (await movementHasDependency(id)) {
      return Failure(DbException.movementHasDependency);
    }
    await (update(movements)
      ..where((m) => m.id.equals(id.toInt()) & m.deleted.equals(false))
    ).write(const MovementsCompanion(deleted: Value(true)));
    return Success(null);
  }
}