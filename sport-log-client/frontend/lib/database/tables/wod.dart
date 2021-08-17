
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/wod/all.dart';

class WodTable extends Table<Wod> {
  @override DbSerializer<Wod> get serde => DbWodSerializer();
  @override String get setupSql => '''
create table wod (
    id integer primary key,
    user_id integer not null,
    date date not null default (datetime('now')),
    description text,
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    unique (user_id, date, deleted)
);
  ''';
  @override String get tableName => 'wod';
}