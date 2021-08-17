
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/cardio/all.dart';

class CardioSessionTable extends Table<CardioSession> {
  @override DbSerializer<CardioSession> get serde => DbCardioSessionSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'cardio_session';
}

class RouteTable extends Table<Route> {
  @override DbSerializer<Route> get serde => DbRouteSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'route';
}
