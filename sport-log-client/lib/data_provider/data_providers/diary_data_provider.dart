import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/diary/diary.dart';

class DiaryDataProvider extends EntityDataProvider<Diary>
    with UnconnectedMethods<Diary> {
  static final instance = DiaryDataProvider._();
  DiaryDataProvider._();

  @override
  final Api<Diary> api = Api.diaries;

  @override
  final DbAccessor<Diary> db = AppDatabase.instance!.diaries;

  @override
  List<Diary> getFromAccountData(AccountData accountData) =>
      accountData.diaries;
}
