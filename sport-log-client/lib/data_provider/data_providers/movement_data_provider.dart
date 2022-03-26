import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/movement/all.dart';

class MovementDataProvider extends EntityDataProvider<Movement> {
  static final _instance = MovementDataProvider._();
  MovementDataProvider._();
  factory MovementDataProvider() => _instance;

  @override
  final Api<Movement> api = Api.movements;

  @override
  final MovementTable db = AppDatabase.movements;

  @override
  List<Movement> getFromAccountData(AccountData accountData) =>
      accountData.movements;

  Future<List<Movement>> getByName(
    String? name, {
    bool cardioOnly = false,
  }) async {
    return await db.getByName(
      name != null && name.isNotEmpty ? name : null,
      cardioOnly: cardioOnly,
    );
  }
}

class MovementDescriptionDataProvider
    extends DataProvider<MovementDescription> {
  final _movementDescriptionDb = AppDatabase.movementDescriptions;

  final _dataProvider = MovementDataProvider();

  static MovementDescriptionDataProvider? _instance;
  MovementDescriptionDataProvider._();
  factory MovementDescriptionDataProvider() {
    if (_instance == null) {
      _instance = MovementDescriptionDataProvider._();
      _instance!._dataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<DbResult> createSingle(MovementDescription object) async {
    return await _dataProvider.createSingle(object.movement);
  }

  @override
  Future<DbResult> updateSingle(MovementDescription object) async {
    return await _dataProvider.updateSingle(object.movement);
  }

  @override
  Future<DbResult> deleteSingle(MovementDescription object) async {
    return await _dataProvider.deleteSingle(object.movement);
  }

  @override
  Future<List<MovementDescription>> getNonDeleted() async {
    return await _movementDescriptionDb.getNonDeleted();
  }

  @override
  Future<bool> pullFromServer() async {
    return await _dataProvider.pullFromServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return await _dataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return await _dataProvider.pushUpdatedToServer();
  }

  Future<List<MovementDescription>> getByName(
    String? name, {
    bool cardioOnly = false,
  }) async {
    return await _movementDescriptionDb.getByName(
      name,
      cardioOnly: cardioOnly,
    );
  }
}
