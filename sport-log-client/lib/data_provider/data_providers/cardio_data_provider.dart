import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/accessors/cardio_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/cardio_tables.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/epoch/epoch_map.dart';
import 'package:sport_log/models/epoch/epoch_result.dart';
import 'package:sport_log/models/movement/movement.dart';

class RouteDataProvider extends EntityDataProvider<Route> {
  factory RouteDataProvider() => _instance;

  RouteDataProvider._();

  static final _instance = RouteDataProvider._();

  @override
  final Api<Route> api = RouteApi();

  @override
  final RouteTable table = RouteTable();

  @override
  List<Route> getFromAccountData(AccountData accountData) => accountData.routes;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.route = epochResult.epoch;
  }

  Future<List<Route>> getByName(String? name) async {
    return (await table.getNonDeleted())
        .fuzzySort(query: name, toString: (m) => m.name);
  }
}

class CardioSessionDataProvider extends EntityDataProvider<CardioSession> {
  factory CardioSessionDataProvider() => _instance;

  CardioSessionDataProvider._();

  static final _instance = CardioSessionDataProvider._();

  @override
  final Api<CardioSession> api = CardioSessionApi();

  @override
  final CardioSessionTable table = CardioSessionTable();

  @override
  List<CardioSession> getFromAccountData(AccountData accountData) =>
      accountData.cardioSessions;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.cardioSession = epochResult.epoch;
  }

  Future<List<CardioSession>> getSimilarCardioSessions(
    CardioSessionDescription cardioSessionDescription,
  ) async {
    final all = await table.getByMovementWithTrackOrderDatetime(
      movement: cardioSessionDescription.movement,
    );
    return all
        .where((c) => cardioSessionDescription.cardioSession.similarTo(c))
        .where((c) => cardioSessionDescription.cardioSession.id != c.id)
        .toList();
  }

  Future<List<(Int64, DateTime, String?)>>
      getIdDatetimeCommentByMovementCommentWithTrack({
    required Movement movement,
    required String? comment,
    required bool hasTrack,
  }) =>
          table.getIdDatetimeCommentByMovementCommentWithTrack(
            movement: movement,
            comment: comment,
            hasTrack: hasTrack,
          );
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

  final _cardioSessionDescriptionDb = CardioSessionDescriptionTable();

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

  Future<CardioSessionDescription?> getById(Int64 id) async {
    final session = await _cardioDataProvider.getById(id);
    if (session == null) {
      return null;
    }
    return CardioSessionDescription(
      cardioSession: session,
      route: await _routeDataProvider.getById(session.id),
      movement: (await _movementDataProvider.getById(session.movementId))!,
    );
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

  Future<List<CardioSessionDescription>> getByTimerangeAndMovementAndComment({
    required DateTime? from,
    required DateTime? until,
    required Movement? movement,
    required String? comment,
  }) async {
    return _cardioSessionDescriptionDb.getByTimerangeAndMovementAndComment(
      from: from,
      until: until,
      movement: movement,
      comment: comment,
    );
  }
}
