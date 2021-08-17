
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementTable extends Table<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  String get setupSql => '''
  ''';

  @override
  String get tableName => 'movement';
}
