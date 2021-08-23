
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/diary/all.dart';

class DiaryTable extends Table<Diary> {
  @override DbSerializer<Diary> get serde => DbDiarySerializer();
  @override String get setupSql => '''
create table diary (
    id integer primary key,
    user_id integer not null,
    date text not null default (datetime('now')),
    bodyweight real check (bodyweight > 0),
    comments text,
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
);
  ''';
  @override String get tableName => 'diary';
}