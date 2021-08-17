
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/diary/all.dart';

class DiaryTable extends Table<Diary> {
  @override DbSerializer<Diary> get serde => DbDiarySerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'diary';
}