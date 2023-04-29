import 'package:sport_log/api/accessors/wod_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/tables/wod_table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodDataProvider extends EntityDataProvider<Wod> {
  factory WodDataProvider() => _instance;

  WodDataProvider._();

  static final _instance = WodDataProvider._();

  @override
  final Api<Wod> api = WodApi();

  @override
  final WodTable table = WodTable();

  @override
  List<Wod> getFromAccountData(AccountData accountData) => accountData.wods;
}
