import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/all.dart';

class MovementTable extends TableAccessor<Movement> {
  factory MovementTable() => _instance;

  MovementTable._();

  static final _instance = MovementTable._();

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
      Column.bool(Columns.isDefaultMovement),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.text(Columns.description)..nullable(),
      Column.bool(Columns.cardio),
      Column.int(Columns.dimension),
    ],
    uniqueColumns: [
      [Columns.name, Columns.dimension],
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
      ]),
      orderBy: orderByName,
    );
    return records.map((r) => serde.fromDbRecord(r)).toList();
  }
}

class MovementDescriptionTable {
  factory MovementDescriptionTable() => _instance;

  MovementDescriptionTable._();

  static final _instance = MovementDescriptionTable._();

  Future<List<MovementDescription>> getNonDeleted() async {
    const hasReference = 'has_reference';
    final records = await AppDatabase.database!.rawQuery(
      '''
      SELECT
        ${MovementTable().table.allColumns},
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
      WHERE ${TableAccessor.notDeletedOfTable(Tables.movement)}
      ORDER BY ${TableAccessor.orderByNameOfTable(Tables.movement)}
      ''',
    );
    return records
        .map(
          (r) => MovementDescription(
            movement: MovementTable()
                .serde
                .fromDbRecord(r, prefix: MovementTable().table.prefix),
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
        ${MovementTable().table.allColumns},
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
          ])}
      ORDER BY ${TableAccessor.orderByNameOfTable(Tables.movement)}
      ''',
    );
    return records
        .map(
          (r) => MovementDescription(
            movement: MovementTable()
                .serde
                .fromDbRecord(r, prefix: MovementTable().table.prefix),
            hasReference: r[hasReference]! as int == 1,
          ),
        )
        .toList();
  }
}
