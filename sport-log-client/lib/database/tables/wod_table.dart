import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/wod/all.dart';

class WodTable extends DbAccessor<Wod> {
  @override
  DbSerializer<Wod> get serde => DbWodSerializer();

  @override
  final Table table = Table(Tables.wod, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.text(Keys.date).withDefault("datetime('now')"),
    Column.text(Keys.description).nullable()
  ]);
}
