import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodDataProvider extends DataProviderImpl<Wod>
    with UnconnectedMethods<Wod> {
  static final instance = WodDataProvider._();
  WodDataProvider._();

  @override
  final ApiAccessor<Wod> api = Api.instance.wods;

  @override
  final DbAccessor<Wod> db = AppDatabase.instance!.wods;

  @override
  List<Wod> getFromAccountData(AccountData accountData) => accountData.wods;
}
