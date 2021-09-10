import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementDataProvider extends DataProviderImpl<Movement>
    with UnconnectedMethods<Movement> {
  @override
  final ApiAccessor<Movement> api = Api.instance.movements;

  @override
  final Table<Movement> db = AppDatabase.instance!.movements;
}
