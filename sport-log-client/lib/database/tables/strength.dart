
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionTable extends Table<StrengthSession> {
  @override DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();
  @override String get setupSql => '''
create table strength_session (
    id integer primary key,
    user_id integer not null,
    datetime text not null default (datetime('now')),
    movement_id integer not null references movement on delete no action,
    movement_unit integer not null check (movement_unit between 0 and 6),
    interval integer check (interval > 0),
    comments text,
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (user_id, datetime, movement_id, deleted)
);
  ''';
  @override String get tableName => 'strength_session';
}

class StrengthSetTable extends Table<StrengthSet> {
  @override DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();
  @override String get setupSql => '''
create table strength_set (
    id integer primary key,
    strength_session_id integer not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 1),
    count integer not null check (count >= 1), -- number of completed movement_unit
    weight real check (weight > 0),
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (strength_session_id, set_number, deleted)
);
  ''';
  @override String get tableName => 'strength_set';
}