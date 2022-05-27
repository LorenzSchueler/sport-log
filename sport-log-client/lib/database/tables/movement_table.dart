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

  Future<List<Movement>> getByCardioAndDistance({
    bool cardioOnly = false,
    bool distanceOnly = false,
  }) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        TableAccessor.cardioOnlyOfTable(cardioOnly),
        TableAccessor.distanceOnlyOfTable(distanceOnly),
        '''(${Columns.userId} IS NOT NULL
          OR NOT EXISTS (
            SELECT * FROM $tableName m2
            WHERE ${TableAccessor.combineFilter([
              "$tableName.${Columns.id} <> m2.${Columns.id}",
              "$tableName.${Columns.name} = m2.${Columns.name}",
              "$tableName.${Columns.dimension} = m2.${Columns.dimension}",
              "m2.${Columns.userId} IS NOT NULL",
            ])}
        ))''',
      ]),
      orderBy: orderByName,
    );
    return records.map((r) => serde.fromDbRecord(r)).toList();
  }
}

class MovementDescriptionTable {
  Future<List<MovementDescription>> getNonDeleted() async {
    const hasReference = 'has_reference';
    final records = await AppDatabase.database!.rawQuery(
      '''
    SELECT
      ${AppDatabase.movements.table.allColumns},
      (
        EXISTS (
          SELECT * FROM ${Tables.metconMovement}
          WHERE ${Tables.metconMovement}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
        ) OR EXISTS (
          SELECT * FROM ${Tables.cardioSession}
          WHERE ${Tables.cardioSession}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
        ) OR EXISTS (
          SELECT * FROM ${Tables.strengthSession}
          WHERE ${Tables.strengthSession}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
        )
      ) AS $hasReference
    FROM ${Tables.movement}
    WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.movement),
            """(${Columns.userId} IS NOT NULL
        OR NOT EXISTS (
          SELECT * FROM ${Tables.movement} m2
          WHERE ${TableAccessor.combineFilter([
                  "${Tables.movement}.${Columns.id} <> m2.${Columns.id}",
                  "${Tables.movement}.${Columns.name} = m2.${Columns.name}",
                  "${Tables.movement}.${Columns.dimension} = m2.${Columns.dimension}",
                  "m2.${Columns.userId} IS NOT NULL",
                ])}
        ))"""
          ])}
    ORDER BY ${TableAccessor.orderByNameOfTable(Tables.movement)}
    ''',
    );
    return records
        .map(
          (r) => MovementDescription(
            movement: AppDatabase.movements.serde
                .fromDbRecord(r, prefix: AppDatabase.movements.table.prefix),
            hasReference: r[hasReference]! as int == 1,
          ),
        )
        .toList();
  }

  Future<List<MovementDescription>> getByCardioAndDistance({
    bool cardioOnly = false,
    bool distanceOnly = false,
  }) async {
    const hasReference = 'has_reference';
    final records = await AppDatabase.database!.rawQuery(
      '''
    SELECT
      ${AppDatabase.movements.table.allColumns},
      (
        EXISTS (
          SELECT * FROM ${Tables.metconMovement}
          WHERE ${Tables.metconMovement}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
        ) OR EXISTS (
          SELECT * FROM ${Tables.cardioSession}
          WHERE ${Tables.cardioSession}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
        ) OR EXISTS (
          SELECT * FROM ${Tables.strengthSession}
          WHERE ${Tables.strengthSession}.${Columns.movementId} = ${Tables.movement}.${Columns.id}
        )
      ) AS $hasReference
    FROM ${Tables.movement}
    WHERE ${TableAccessor.combineFilter([
            TableAccessor.notDeletedOfTable(Tables.movement),
            TableAccessor.cardioOnlyOfTable(cardioOnly),
            TableAccessor.distanceOnlyOfTable(distanceOnly),
            """(${Columns.userId} IS NOT NULL
        OR NOT EXISTS (
          SELECT * FROM ${Tables.movement} m2
          WHERE ${TableAccessor.combineFilter([
                  "${Tables.movement}.${Columns.id} <> m2.${Columns.id}",
                  "${Tables.movement}.${Columns.name} = m2.${Columns.name}",
                  "${Tables.movement}.${Columns.dimension} = m2.${Columns.dimension}",
                  "m2.${Columns.userId} IS NOT NULL",
                ])}
        ))"""
          ])}
    ORDER BY ${TableAccessor.orderByNameOfTable(Tables.movement)}
    ''',
    );
    return records
        .map(
          (r) => MovementDescription(
            movement: AppDatabase.movements.serde
                .fromDbRecord(r, prefix: AppDatabase.movements.table.prefix),
            hasReference: r[hasReference]! as int == 1,
          ),
        )
        .toList();
  }
}
