import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodDataProvider extends DataProviderImpl<Wod>
    with UnconnectedMethods<Wod> {
  @override
  final ApiAccessor<Wod> api = Api.instance.wods;

  @override
  final DbAccessor<Wod> db = AppDatabase.instance!.wods;
}
