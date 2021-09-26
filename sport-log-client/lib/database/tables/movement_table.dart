import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementTable extends DbAccessor<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  List<String> get setupSql => [
        _table.setupSql(),
        '''
      CREATE UNIQUE INDEX unique_movement_idx
      ON $tableName ($name, $unit, $userId)
      WHERE $deleted = 0;
      ''',
        updateTrigger,
      ];

  final Table _table = Table(
    Tables.movement,
    withColumns: [
      Column.int(Keys.id).primaryKey(),
      Column.bool(Keys.deleted).withDefault('0'),
      Column.int(Keys.syncStatus)
          .withDefault('2')
          .check('${Keys.syncStatus} IN (0, 1, 2)'),
      Column.int(Keys.userId).nullable(),
      Column.text(Keys.name),
      Column.text(Keys.description).nullable(),
      Column.bool(Keys.cardio),
      Column.int(Keys.unit),
    ],
  );

  static const cardioSession = Tables.cardioSession;
  static const deleted = Keys.deleted;
  static const id = Keys.id;
  static const metconMovement = Tables.metconMovement;
  static const movementId = Keys.movementId;
  static const name = Keys.name;
  static const strengthSession = Tables.strengthSession;
  static const unit = Keys.unit;
  static const userId = Keys.userId;

  @override
  String get tableName => _table.name;

  Table get table => _table;

  final _logger = Logger('MovementTable');

  Future<List<MovementDescription>> getMovementDescriptions() async {
    // TODO: check for references to cardio blueprint, strength blueprint
    final now = DateTime.now();
    const hasReference = 'has_reference';
    final records = await database.rawQuery('''
    SELECT
      ${_table.allColumns},
      (
        EXISTS (
          SELECT * FROM $metconMovement
          WHERE $metconMovement.$movementId = $tableName.$id
        ) OR EXISTS (
          SELECT * FROM $cardioSession
          WHERE $cardioSession.$movementId = $tableName.$id
        ) OR EXISTS (
          SELECT * FROM $strengthSession
          WHERE $strengthSession.$movementId = $tableName.$id
        )
      ) AS $hasReference
    FROM $tableName
    WHERE $tableName.$deleted = 0
      AND ($userId IS NOT NULL
        OR NOT EXISTS (
          SELECT * FROM $tableName m2
          WHERE $tableName.$id <> m2.$id
            AND $tableName.$name = m2.$name
            AND $tableName.$unit = m2.$unit
            AND m2.$userId IS NOT NULL
        )
      )
    ORDER BY $name
    ''');
    _logger.d('Select movement descriptions: ' +
        DateTime.now().difference(now).toString());
    return records
        .map((r) => MovementDescription(
              movement: serde.fromDbRecord(r, prefix: _table.prefix),
              hasReference: r[hasReference]! as int == 1,
            ))
        .toList();
  }

  Future<List<Movement>> getMovements({
    String? byName,
  }) async {
    final nameFilter = byName != null ? '$name LIKE ?' : '1 = 1';
    final records = await database.rawQuery('''
      SELECT * FROM $tableName m1
      WHERE $deleted = 0
        AND $nameFilter
        AND ($userId IS NOT NULL
          OR NOT EXISTS (
            SELECT * FROM $tableName m2
            WHERE m1.$id <> m2.$id
              AND m1.$name = m2.$name
              AND m1.$unit = m2.$unit
              AND m2.$userId IS NOT NULL
          )
        )
      ORDER BY $name
    ''', [if (byName != null) '%$byName%']);
    return records.map((r) => serde.fromDbRecord(r)).toList();
  }

  Future<bool> exists(String nameValue, MovementUnit unitValue) async {
    final result = await database.rawQuery('''
      SELECT 1 FROM $tableName
      WHERE $deleted = 0
        AND $name = ?
        AND $unit = ?
    ''', [nameValue, unitValue.index]);
    return result.isNotEmpty;
  }
}
