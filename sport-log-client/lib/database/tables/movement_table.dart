import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/all.dart';

class MovementTable extends TableAccessor<Movement> {
  @override
  DbSerializer<Movement> get serde => DbMovementSerializer();

  @override
  final Table table = Table(
    name: Tables.movement,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId)..nullable(),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.text(Columns.description)..nullable(),
      Column.bool(Columns.cardio),
      Column.int(Columns.dimension),
    ],
    uniqueColumns: [
      [Columns.name, Columns.dimension]
    ],
  );

  static const cardioSession = Tables.cardioSession;
  static const metconMovement = Tables.metconMovement;
  static const strengthSession = Tables.strengthSession;

  static const id = Columns.id;
  static const name = Columns.name;
  static const dimension = Columns.dimension;
  static const userId = Columns.userId;

  Future<List<Movement>> getByName(
    String? byName, {
    bool cardioOnly = false,
  }) async {
    final records = await database.rawQuery(
      '''
      SELECT * FROM $tableName
      WHERE ${TableAccessor.combineFilter([
            notDeleted,
            nameFilter(byName),
            cardioOnly ? '${Columns.cardio} = true' : ''
          ])}
        AND ($userId IS NOT NULL
          OR NOT EXISTS (
            SELECT * FROM $tableName m2
            WHERE movement.$id <> m2.$id
              AND movement.$name = m2.$name
              AND movement.$dimension = m2.$dimension
              AND m2.$userId IS NOT NULL
          )
        )
      ORDER BY $orderByName
    ''',
      [if (byName != null && byName.isNotEmpty) '%$byName%'],
    );
    return records.map((r) => serde.fromDbRecord(r)).toList();
  }
}

class MovementDescriptionTable {
  static const cardioSession = Tables.cardioSession;
  static const strengthSession = Tables.strengthSession;
  static const metconMovement = Tables.metconMovement;
  static const movement = Tables.movement;

  static const deleted = Columns.deleted;
  static const id = Columns.id;
  static const movementId = Columns.movementId;
  static const name = Columns.name;
  static const dimension = Columns.dimension;
  static const userId = Columns.userId;

  static MovementTable get _movementTable => AppDatabase.movements;

  Future<List<MovementDescription>> getNonDeleted() async {
    const hasReference = 'has_reference';
    final records = await AppDatabase.database!.rawQuery(
      '''
    SELECT
      ${_movementTable.table.allColumns},
      (
        EXISTS (
          SELECT * FROM $metconMovement
          WHERE $metconMovement.$movementId = $movement.$id
        ) OR EXISTS (
          SELECT * FROM $cardioSession
          WHERE $cardioSession.$movementId = $movement.$id
        ) OR EXISTS (
          SELECT * FROM $strengthSession
          WHERE $strengthSession.$movementId = $movement.$id
        )
      ) AS $hasReference
    FROM $movement
    WHERE ${TableAccessor.notDeletedOfTable(movement)}
      AND ($userId IS NOT NULL
        OR NOT EXISTS (
          SELECT * FROM $movement m2
          WHERE $movement.$id <> m2.$id
            AND $movement.$name = m2.$name
            AND $movement.$dimension = m2.$dimension
            AND m2.$userId IS NOT NULL
        )
      )
    ORDER BY $name COLLATE NOCASE
    ''',
    );
    return records
        .map(
          (r) => MovementDescription(
            movement: _movementTable.serde
                .fromDbRecord(r, prefix: _movementTable.table.prefix),
            hasReference: r[hasReference]! as int == 1,
          ),
        )
        .toList();
  }

  Future<List<MovementDescription>> getByName(
    String? byName, {
    bool cardioOnly = false,
  }) async {
    const hasReference = 'has_reference';
    final nameFilter = byName != null ? 'AND $name LIKE ?' : '';
    final cardioFilter = cardioOnly ? 'AND cardio = true' : '';
    final records = await AppDatabase.database!.rawQuery(
      '''
    SELECT
      ${_movementTable.table.allColumns},
      (
        EXISTS (
          SELECT * FROM $metconMovement
          WHERE $metconMovement.$movementId = $movement.$id
        ) OR EXISTS (
          SELECT * FROM $cardioSession
          WHERE $cardioSession.$movementId = $movement.$id
        ) OR EXISTS (
          SELECT * FROM $strengthSession
          WHERE $strengthSession.$movementId = $movement.$id
        )
      ) AS $hasReference
    FROM $movement
    WHERE ${TableAccessor.notDeletedOfTable(movement)}
      $nameFilter
      $cardioFilter
      AND ($userId IS NOT NULL
        OR NOT EXISTS (
          SELECT * FROM $movement m2
          WHERE $movement.$id <> m2.$id
            AND $movement.$name = m2.$name
            AND $movement.$dimension = m2.$dimension
            AND m2.$userId IS NOT NULL
        )
      )
    ORDER BY $name COLLATE NOCASE
    ''',
    );
    return records
        .map(
          (r) => MovementDescription(
            movement: _movementTable.serde
                .fromDbRecord(r, prefix: _movementTable.table.prefix),
            hasReference: r[hasReference]! as int == 1,
          ),
        )
        .toList();
  }
}
