
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconTable extends Table<Metcon> {
  @override String get setupSql => '''
  ''';
  @override DbSerializer<Metcon> get serde => DbMetconSerializer();
  @override String get tableName => 'metcon';
}

class MetconMovementTable extends Table<MetconMovement> {
  @override DbSerializer<MetconMovement> get serde => DbMetconMovementSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'metcon_movement';
}

class MetconSessionTable extends Table<MetconSession> {
  @override DbSerializer<MetconSession> get serde => DbMetconSessionSerializer();
  @override
  String get setupSql => '''
  ''';
  @override String get tableName => 'metcon_session';
}
