import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/movement/all.dart';

class MovementDataProvider extends EntityDataProvider<Movement> {
  factory MovementDataProvider() => _instance;

  MovementDataProvider._();

  static final _instance = MovementDataProvider._();

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
    bool distanceOnly = false,
  }) async {
    return (await db.getByCardioAndDistance(
      cardioOnly: cardioOnly,
      distanceOnly: distanceOnly,
    ))
        .fuzzySort(query: name, toString: (m) => m.name);
  }
}

class MovementDescriptionDataProvider
    extends DataProvider<MovementDescription> {
  factory MovementDescriptionDataProvider() {
    if (_instance == null) {
      _instance = MovementDescriptionDataProvider._();
      _instance!._dataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  MovementDescriptionDataProvider._();

  static MovementDescriptionDataProvider? _instance;

  final _movementDescriptionDb = AppDatabase.movementDescriptions;

  final _dataProvider = MovementDataProvider();

  @override
  Future<DbResult> createSingle(MovementDescription object) async {
    return _dataProvider.createSingle(object.movement);
  }

  @override
  Future<DbResult> updateSingle(MovementDescription object) async {
    return _dataProvider.updateSingle(object.movement);
  }

  @override
  Future<DbResult> deleteSingle(MovementDescription object) async {
    return _dataProvider.deleteSingle(object.movement);
  }

  @override
  Future<List<MovementDescription>> getNonDeleted() async {
    return _movementDescriptionDb.getNonDeleted();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return _dataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return _dataProvider.pushUpdatedToServer();
  }

  Future<List<MovementDescription>> getByName(
    String? name, {
    bool cardioOnly = false,
    bool distanceOnly = false,
  }) async {
    return (await _movementDescriptionDb.getByCardioAndDistance(
      cardioOnly: cardioOnly,
      distanceOnly: distanceOnly,
    ))
        .fuzzySort(query: name, toString: (m) => m.movement.name);
  }
}
