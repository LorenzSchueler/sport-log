import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/diary_table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/diary/diary.dart';

class DiaryDataProvider extends EntityDataProvider<Diary> {
  factory DiaryDataProvider() => _instance;

  DiaryDataProvider._();

  static final _instance = DiaryDataProvider._();

  @override
  final Api<Diary> api = Api.diaries;

  @override
  final DiaryTable db = AppDatabase.diaries;

  @override
  List<Diary> getFromAccountData(AccountData accountData) =>
      accountData.diaries;

  Future<List<Diary>> getByTimerangeAndComment({
    required DateTime? from,
    required DateTime? until,
    required String? comment,
  }) async {
    return db.getByTimerangeAndComment(from, until, comment);
  }
}
