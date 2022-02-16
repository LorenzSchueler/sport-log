import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/movement/all.dart';

class MovementDataProvider extends EntityDataProvider<Movement> {
  static final instance = MovementDataProvider._();
  MovementDataProvider._();

  @override
  final Api<Movement> api = Api.movements;

  @override
  final MovementTable db = AppDatabase.instance!.movements;

  Future<List<MovementDescription>> getMovementDescriptions() async =>
      db.getMovementDescriptions();

  Future<List<Movement>> getMovements(
          {String? byName, bool cardioOnly = false}) async =>
      db.getMovements(
          byName: byName != null && byName.isNotEmpty ? byName : null,
          cardioOnly: cardioOnly);

  Future<bool> movementExists(String name, MovementDimension dim) async =>
      db.exists(name, dim);

  @override
  List<Movement> getFromAccountData(AccountData accountData) =>
      accountData.movements;
}
