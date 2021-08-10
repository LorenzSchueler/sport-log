
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/movements/movement_table.dart';

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
}