import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/account_data/all.dart';
import 'package:sport_log/models/cardio/all.dart';

class RouteDataProvider extends EntityDataProvider<Route> {
  static final instance = RouteDataProvider._();
  RouteDataProvider._();

  @override
  final Api<Route> api = Api.routes;

  @override
  final TableAccessor<Route> db = AppDatabase.routes;

  @override
  List<Route> getFromAccountData(AccountData accountData) => accountData.routes;
}

class CardioSessionDataProvider extends EntityDataProvider<CardioSession> {
  static final instance = CardioSessionDataProvider._();
  CardioSessionDataProvider._();

  @override
  final Api<CardioSession> api = Api.cardioSessions;

  @override
  final TableAccessor<CardioSession> db = AppDatabase.cardioSessions;

  @override
  List<CardioSession> getFromAccountData(AccountData accountData) =>
      accountData.cardioSessions;
}
