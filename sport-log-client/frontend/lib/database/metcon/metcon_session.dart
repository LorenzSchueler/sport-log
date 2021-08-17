
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/metcon_session.dart';

class MetconSessionTable extends Table<MetconSession> {
  @override
  DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();

  @override
  String get setupSql => '''
create table metcon_session (
    id integer primary key,
    user_id integer not null,
    metcon_id integer not null references metcon(id),
    datetime text not null,
    time integer check (time > 0), -- seconds
    rounds integer check (rounds >= 0),
    reps integer check (reps >= 0),
    rx integer not null,
    comments text,
    last_change text not null default (datetime('now')),
    deleted boolean not null default false,
    unique (user_id, metcon_id, datetime, deleted)
);
  ''';

  @override
  String get tableName => 'metcon_session';
}