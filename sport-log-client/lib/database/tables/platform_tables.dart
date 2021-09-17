
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends Table<Platform> {
  @override DbSerializer<Platform> get serde => DbPlatformSerializer();
  @override String get setupSql => '''
create table $tableName (
    name text not null check (length(name) between 3 and 80),
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => Tables.platform;
}

class PlatformCredentialTable extends Table<PlatformCredential> {
  @override DbSerializer<PlatformCredential> get serde => DbPlatformCredentialSerializer();
  @override String get setupSql => '''
create table $tableName (
    user_id integer not null,
    platform_id integer not null references platform on delete cascade,
    username text not null check (length(username) between 1 and 80),
    password text null check (length(password) between 1 and 80),
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => Tables.platformCredential;
}