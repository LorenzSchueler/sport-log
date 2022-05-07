import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/cardio_tables.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/movement/movement.dart';

class RouteDataProvider extends EntityDataProvider<Route> {
  static final _instance = RouteDataProvider._();
  RouteDataProvider._();
  factory RouteDataProvider() => _instance;

  @override
  final Api<Route> api = Api.routes;

  @override
  final RouteTable db = AppDatabase.routes;

  @override
  List<Route> getFromAccountData(AccountData accountData) => accountData.routes;

  Future<List<Route>> getByName(String? name) async {
    return (await db.getNonDeleted())
        .sortByKey(key: name, toString: (m) => m.name);
  }
}

class CardioSessionDataProvider extends EntityDataProvider<CardioSession> {
  static final _instance = CardioSessionDataProvider._();
  CardioSessionDataProvider._();
  factory CardioSessionDataProvider() => _instance;

  @override
  final Api<CardioSession> api = Api.cardioSessions;

  @override
  final TableAccessor<CardioSession> db = AppDatabase.cardioSessions;

  @override
  List<CardioSession> getFromAccountData(AccountData accountData) =>
      accountData.cardioSessions;
}

class CardioSessionDescriptionDataProvider
    extends DataProvider<CardioSessionDescription> {
  final _cardioSessionDescriptionDb = AppDatabase.cardioSessionDescriptions;

  final _cardioDataProvider = CardioSessionDataProvider();
  final _routeDataProvider = RouteDataProvider();
  final _movementDataProvider = MovementDataProvider();

  static CardioSessionDescriptionDataProvider? _instance;
  CardioSessionDescriptionDataProvider._();
  factory CardioSessionDescriptionDataProvider() {
    if (_instance == null) {
      _instance = CardioSessionDescriptionDataProvider._();
      _instance!._cardioDataProvider.addListener(_instance!.notifyListeners);
      _instance!._routeDataProvider.addListener(_instance!.notifyListeners);
      _instance!._movementDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<DbResult> createSingle(CardioSessionDescription object) async {
    return await _cardioDataProvider.createSingle(object.cardioSession);
  }

  @override
  Future<DbResult> updateSingle(CardioSessionDescription object) async {
    return await _cardioDataProvider.updateSingle(object.cardioSession);
  }

  @override
  Future<DbResult> deleteSingle(CardioSessionDescription object) async {
    return await _cardioDataProvider.deleteSingle(object.cardioSession);
  }

  @override
  Future<List<CardioSessionDescription>> getNonDeleted() async {
    return Future.wait(
      (await _cardioDataProvider.getNonDeleted())
          .map(
            (session) async => CardioSessionDescription(
              cardioSession: session,
              route: await _routeDataProvider.getById(session.id),
              movement:
                  (await _movementDataProvider.getById(session.movementId))!,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<bool> pullFromServer() async {
    if (!await _movementDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    if (!await _routeDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    return await _cardioDataProvider.pullFromServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return await _cardioDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return await _cardioDataProvider.pushUpdatedToServer();
  }

  Future<List<CardioSessionDescription>> getByTimerangeAndMovement({
    Movement? movement,
    DateTime? from,
    DateTime? until,
  }) async {
    return _cardioSessionDescriptionDb.getByTimerangeAndMovement(
      from: from,
      until: until,
      movementValue: movement,
    );
  }
}
