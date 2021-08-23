
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementTable extends Table<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  String get setupSql => '''
create table movement (
    user_id integer,
    name text not null,
    description text,
    category integer not null check (category in (0, 1)),
    last_change text not null default (datetime('now')),
    $idAndDeletedAndStatus
);
  ''';

  @override
  String get tableName => 'movement';
}
