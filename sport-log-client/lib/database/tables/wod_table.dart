import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/wod/all.dart';

class WodTable extends TableAccessor<Wod> {
  @override
  DbSerializer<Wod> get serde => DbWodSerializer();

  @override
  final Table table = Table(Tables.wod, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.text(Columns.date).withDefault("datetime('now')"),
    Column.text(Columns.description).nullable()
  ]);
}
