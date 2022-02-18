import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/diary/all.dart';

class DiaryTable extends TableAccessor<Diary> {
  @override
  DbSerializer<Diary> get serde => DbDiarySerializer();

  @override
  final Table table = Table(Tables.diary, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.text(Columns.date).withDefault("datetime('now')"),
    Column.real(Columns.bodyweight)
        .nullable()
        .check("${Columns.bodyweight} > 0"),
    Column.text(Columns.comments).nullable()
  ]);

  Future<List<Diary>> getByTimerange({
    DateTime? from,
    DateTime? until,
  }) async {
    return []; // TODO implement
    //final fromFilter = from == null ? '' : 'AND $tableName.$datetime >= ?';
    //final untilFilter = until == null ? '' : 'AND $tableName.$datetime < ?';
    //final records = await database.rawQuery('''
    //SELECT
    //${_table.allColumns},
    //FROM $tableName
    //WHERE $tableName.${Keys.deleted} = 0
    //$fromFilter
    //$untilFilter
    //ORDER BY
    //datetime($tableName.${Keys.datetime}) DESC;
    //''', [
    //if (from != null) from.toString(),
    //if (until != null) until.toString(),
    //]);
    //return records.mapToL((record) => StrengthSessionWithStats(
    //session: serde.fromDbRecord(record, prefix: _table.prefix),
    //movement: _movementTable.serde
    //.fromDbRecord(record, prefix: _movementTable.table.prefix),
    //stats: StrengthSessionStats.fromDbRecord(record),
    //));
  }
}
