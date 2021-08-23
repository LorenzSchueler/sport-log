
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/wod/all.dart';

class WodTable extends Table<Wod> {
  @override DbSerializer<Wod> get serde => DbWodSerializer();
  @override String get setupSql => '''
create table wod (
    user_id integer not null,
    date date not null default (datetime('now')),
    description text,
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => 'wod';
}