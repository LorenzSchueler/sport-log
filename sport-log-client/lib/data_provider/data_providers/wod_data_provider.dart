import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodDataProvider extends EntityDataProvider<Wod> {
  static final instance = WodDataProvider._();
  WodDataProvider._();

  @override
  final Api<Wod> api = Api.wods;

  @override
  final DbAccessor<Wod> db = AppDatabase.wods;

  @override
  List<Wod> getFromAccountData(AccountData accountData) => accountData.wods;
}
