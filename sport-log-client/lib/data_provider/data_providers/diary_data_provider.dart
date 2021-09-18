import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/diary/diary.dart';

class DiaryDataProvider extends DataProviderImpl<Diary>
    with UnconnectedMethods<Diary> {
  @override
  final ApiAccessor<Diary> api = Api.instance.diaries;

  // FIXME: nullable unwrap!
  @override
  final DbAccessor<Diary> db = AppDatabase.instance!.diaries;
}
