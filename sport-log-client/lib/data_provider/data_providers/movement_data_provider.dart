import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/helpers/extensions/result_extension.dart';
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
    return (await db.searchByName(name)).orDo((e) {
      handleDbError(e);
      return [];
    });
  }

  Future<List<MovementDescription>> getNonDeletedFull() async {
    return (await db.getNonDeletedFull()).orDo((fail) {
      handleDbError(fail);
      return [];
    });
  }
}
