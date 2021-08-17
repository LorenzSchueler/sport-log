
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionTable extends Table<StrengthSession> {
  @override DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'strength_session';
}

class StrengthSetTable extends Table<StrengthSet> {
  @override DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();
  @override String get setupSql => '''
  ''';
  @override String get tableName => 'strength_set';
}