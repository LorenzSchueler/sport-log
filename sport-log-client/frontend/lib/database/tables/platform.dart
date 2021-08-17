
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends Table<Platform> {
  @override DbSerializer<Platform> get serde => DbPlatformSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'platform';
}

class PlatformCredentialTable extends Table<PlatformCredential> {
  @override DbSerializer<PlatformCredential> get serde => DbPlatformCredentialSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'platform_credential';
}