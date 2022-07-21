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
  factory RouteDataProvider() => _instance;

  RouteDataProvider._();

  static final _instance = RouteDataProvider._();

  @override
  final Api<Route> api = Api.routes;

  @override
  final RouteTable db = AppDatabase.routes;

  @override
  List<Route> getFromAccountData(AccountData accountData) => accountData.routes;

  Future<List<Route>> getByName(String? name) async {
    return (await db.getNonDeleted())
        .fuzzySort(query: name, toString: (m) => m.name);
  }
}

class CardioSessionDataProvider extends EntityDataProvider<CardioSession> {
  factory CardioSessionDataProvider() => _instance;

  CardioSessionDataProvider._();

  static final _instance = CardioSessionDataProvider._();

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
  factory CardioSessionDescriptionDataProvider() {
    if (_instance == null) {
      _instance = CardioSessionDescriptionDataProvider._();
      _instance!._cardioDataProvider.addListener(_instance!.notifyListeners);
      _instance!._routeDataProvider.addListener(_instance!.notifyListeners);
      _instance!._movementDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }
  CardioSessionDescriptionDataProvider._();

  static CardioSessionDescriptionDataProvider? _instance;

  final _cardioSessionDescriptionDb = AppDatabase.cardioSessionDescriptions;

  final _cardioDataProvider = CardioSessionDataProvider();
  final _routeDataProvider = RouteDataProvider();
  final _movementDataProvider = MovementDataProvider();

  @override
  Future<DbResult> createSingle(CardioSessionDescription object) async {
    return _cardioDataProvider.createSingle(object.cardioSession);
  }

  @override
  Future<DbResult> updateSingle(CardioSessionDescription object) async {
    return _cardioDataProvider.updateSingle(object.cardioSession);
  }

  @override
  Future<DbResult> deleteSingle(CardioSessionDescription object) async {
    return _cardioDataProvider.deleteSingle(object.cardioSession);
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
    return _cardioDataProvider.pullFromServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return _cardioDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return _cardioDataProvider.pushUpdatedToServer();
  }

  Future<List<CardioSessionDescription>> getByTimerangeAndMovement({
    required Movement? movement,
    required DateTime? from,
    required DateTime? until,
  }) async {
    return _cardioSessionDescriptionDb.getByTimerangeAndMovement(
      from: from,
      until: until,
      movementValue: movement,
    );
  }
}
