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

  Future<bool> exists(String name, MovementDimension dim) async {
    return await db.exists(name, dim);
  }
}

class MovementDescriptionDataProvider
    extends DataProvider<MovementDescription> {
  final _movementDescriptionDb = AppDatabase.movementDescriptions;

  final _dataProvider = MovementDataProvider.instance;

  MovementDescriptionDataProvider._();
  static MovementDescriptionDataProvider? _instance;
  static MovementDescriptionDataProvider get instance {
    if (_instance == null) {
      _instance = MovementDescriptionDataProvider._();
      _instance!._dataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<bool> createSingle(MovementDescription object) async {
    return await _dataProvider.createSingle(object.movement);
  }

  @override
  Future<bool> updateSingle(MovementDescription object) async {
    return await _dataProvider.updateSingle(object.movement);
  }

  @override
  Future<bool> deleteSingle(MovementDescription object) async {
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

  Future<bool> exists(String name, MovementDimension dim) async {
    return await _dataProvider.exists(name, dim);
  }
}
