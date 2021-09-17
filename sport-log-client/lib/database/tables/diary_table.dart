
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/diary/all.dart';

class DiaryTable extends Table<Diary> {
  @override DbSerializer<Diary> get serde => DbDiarySerializer();
  @override String get setupSql => '''
create table $tableName (
    user_id integer not null,
    date text not null default (datetime('now')),
    bodyweight real check (bodyweight > 0),
    comments text,
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => Tables.diary;
}