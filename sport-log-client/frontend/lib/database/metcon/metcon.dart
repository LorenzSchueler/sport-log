
import 'dart:io';

import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/all.dart';

class MetconTable extends Table<Metcon> {
  @override
  String get setupSql => '''
create table metcon (
    id integer primary key,
    user_id integer,
    name text,
    metcon_type integer not null,
    rounds integer check (rounds >= 1),
    timecap integer check (timecap > 0), -- seconds
    description text,
    last_change text not null default (datetime('now')),
    deleted boolean not null default false,
    unique (user_id, name, deleted)
);
  ''';

  @override
  DbSerializer<Metcon> get serde => DbMetconSerializer();

  @override
  String get tableName => 'metcon';
}