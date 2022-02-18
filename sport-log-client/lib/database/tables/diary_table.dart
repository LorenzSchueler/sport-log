import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/diary/all.dart';

class DiaryTable extends DbAccessor<Diary> {
  @override
  DbSerializer<Diary> get serde => DbDiarySerializer();

  @override
  final Table table = Table(Tables.diary, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.text(Keys.date).withDefault("datetime('now')"),
    Column.real(Keys.bodyweight).nullable().check("${Keys.bodyweight} > 0"),
    Column.text(Keys.comments).nullable()
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
