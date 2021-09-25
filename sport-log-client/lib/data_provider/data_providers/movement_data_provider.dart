import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/models/movement/all.dart';

class MovementDataProvider extends DataProviderImpl<Movement>
    with UnconnectedMethods<Movement> {
  @override
  final ApiAccessor<Movement> api = Api.instance.movements;

  @override
  final MovementTable db = AppDatabase.instance!.movements;

  Future<List<Movement>> searchByName(String name) async {
    if (name.isEmpty) {
      return getNonDeleted();
    }
    return db.searchByName(name);
  }

  Future<List<MovementDescription>> getNonDeletedFull() async =>
      db.getNonDeletedFull();

  Future<List<Movement>> getStrengthSessionMovements() async =>
      db.getMovementsWithUnits([
        MovementUnit.m,
        MovementUnit.cals,
        MovementUnit.msecs,
        MovementUnit.reps
      ]);
}
