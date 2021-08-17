
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementTable extends Table<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  String get setupSql => '''
create table movement (
    id integer primary key,
    user_id integer,
    name text not null,
    description text,
    category integer not null,
    last_change text not null default (datetime('now')),
    deleted boolean not null default false,
    unique (user_id, name, category, deleted)
);
  ''';

  @override
  String get tableName => 'movement';
}