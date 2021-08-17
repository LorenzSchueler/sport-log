
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/metcon_movement.dart';

class MetconMovementTable extends Table<MetconMovement> {
  @override
  DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();

  @override
  String get setupSql => '''
create table metcon_movement (
    id integer primary key,
    metcon_id integer not null references metcon(id),
    movement_id integer not null references movement(id),
    movement_number integer not null check (movement_number >= 1),
    count integer not null check (count >= 1),
    movement_unit integer not null,
    weight real check (weight > 0),
    last_change text not null default (datetime('now')),
    deleted boolean not null default false,
    unique (metcon_id, movement_number, deleted)
);
  ''';

  @override
  String get tableName => 'metcon_movement';
}