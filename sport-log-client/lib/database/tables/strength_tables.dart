import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionTable extends DbAccessor<StrengthSession>
    with DateTimeMethods {
  final _logger = Logger('StrengthSessionTable');

  @override
  DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();
  @override
  String get setupSql => _table.setupSql();
  @override
  String get tableName => _table.name;

  final Table _table = Table(Tables.strengthSession, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.text(Keys.datetime).withDefault("DATETIME('now')"),
    Column.int(Keys.movementId)
        .references(Tables.movement, onDelete: OnAction.cascade),
    Column.int(Keys.movementUnit).check('${Keys.movementUnit} BETWEEN 0 AND 6'),
    Column.int(Keys.interval).nullable().check('${Keys.interval} > 0'),
    Column.text(Keys.comments).nullable(),
  ]);

  Future<List<StrengthSessionDescription>> getDescriptions() async {
    final movementTable = AppDatabase.instance!.movements;
    const strengthSet = Tables.strengthSet;
    const movement = Tables.movement;
    const strengthSessionId = Keys.strengthSessionId;
    const id = Keys.id;
    const movementId = Keys.movementId;
    const deleted = Keys.deleted;
    const datetime = Keys.datetime;
    final allColumns =
        [_table.allColumns, movementTable.table.allColumns].join(', ');
    final result = await database.rawQuery('''
    SELECT $allColumns, COUNT($strengthSet.$id) AS num_sets FROM $tableName
    JOIN $strengthSet ON $tableName.$id = $strengthSet.$strengthSessionId
    JOIN $movement ON $tableName.$movementId = $movement.$id
    WHERE $tableName.$deleted = 0 AND $strengthSet.$deleted = 0
    GROUP BY $tableName.$id
    ORDER BY datetime($datetime) DESC;
    ''');
    _logger.d(result.first);
    return result
        .map((record) => StrengthSessionDescription(
              strengthSession:
                  serde.fromDbRecord(record, prefix: _table.prefix),
              strengthSets: null,
              movement: movementTable.serde
                  .fromDbRecord(record, prefix: movementTable.table.prefix),
            ))
        .toList();
  }
}

class StrengthSetTable extends DbAccessor<StrengthSet> {
  @override
  DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();
  @override
  String get setupSql => '''
create table $tableName (
    strength_session_id integer not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 0),
    count integer not null check (count >= 1), -- number of completed movement_unit
    weight real check (weight > 0),
    $idAndDeletedAndStatus
);
  ''';
  @override
  String get tableName => Tables.strengthSet;

  Future<void> setSynchronizedByStrengthSession(Int64 id) async {
    database.update(tableName, DbAccessor.synchronized,
        where: '${Keys.strengthSessionId} = ?', whereArgs: [id.toInt()]);
  }

  Future<List<StrengthSet>> getByStrengthSession(Int64 id) async {
    final result = await database.query(tableName,
        where: '${Keys.strengthSessionId} = ? AND ${Keys.deleted} = 0',
        whereArgs: [id.toInt()],
        orderBy: Keys.setNumber);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByStrengthSession(Int64 id) async {
    await database.update(tableName, {Keys.deleted: 1},
        where: '${Keys.strengthSessionId} = ? AND ${Keys.deleted} = 0',
        whereArgs: [id.toInt()]);
  }
}
