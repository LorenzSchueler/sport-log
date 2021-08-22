
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends Table<Platform> {
  @override DbSerializer<Platform> get serde => DbPlatformSerializer();
  @override String get setupSql => '''
create table platform (
    id integer primary key,
    name text not null check (length(name) between 3 and 80),
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (name, deleted)
);
  ''';
  @override String get tableName => 'platform';
}

class PlatformCredentialTable extends Table<PlatformCredential> {
  @override DbSerializer<PlatformCredential> get serde => DbPlatformCredentialSerializer();
  @override String get setupSql => '''
create table platform_credential (
    id integer primary key,
    user_id integer not null,
    platform_id integer not null references platform on delete cascade,
    username text not null check (length(username) between 1 and 80),
    password text null check (length(password) between 1 and 80),
    last_change text not null default (datetime('now')),
    deleted integer not null default 0 check (deleted in (0, 1)),
    is_new integer not null check (is_new in (0, 1)),
    unique (user_id, platform_id, deleted)
);
  ''';
  @override String get tableName => 'platform_credential';
}