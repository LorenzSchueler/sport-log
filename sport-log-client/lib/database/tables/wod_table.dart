import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/wod/all.dart';

class WodTable extends DbAccessor<Wod> {
  @override
  DbSerializer<Wod> get serde => DbWodSerializer();
  @override
  List<String> get setupSql => ['''
  create table $tableName (
      user_id integer not null,
      date date not null default (datetime('now')),
      description text,
      $idAndDeletedAndStatus
  );
  ''', updateTrigger];
  @override
  String get tableName => Tables.wod;
}
