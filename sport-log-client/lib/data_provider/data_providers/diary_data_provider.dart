import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/diary_table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/diary/diary.dart';

class DiaryDataProvider extends EntityDataProvider<Diary> {
  static final _instance = DiaryDataProvider._();
  DiaryDataProvider._();
  factory DiaryDataProvider() => _instance;

  @override
  final Api<Diary> api = Api.diaries;

  @override
  final DiaryTable db = AppDatabase.diaries;

  @override
  List<Diary> getFromAccountData(AccountData accountData) =>
      accountData.diaries;

  Future<List<Diary>> getByTimerange({
    required DateTime? from,
    required DateTime? until,
  }) async {
    return await db.getByTimerange(from, until);
  }
}
