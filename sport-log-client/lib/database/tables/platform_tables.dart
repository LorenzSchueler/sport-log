import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends DbAccessor<Platform> {
  @override
  DbSerializer<Platform> get serde => DbPlatformSerializer();

  @override
  final Table table = Table(Tables.platform, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.text(Keys.name).check("length(${Keys.name}) between 3 and 80"),
  ]);
}

class PlatformCredentialTable extends DbAccessor<PlatformCredential> {
  @override
  DbSerializer<PlatformCredential> get serde =>
      DbPlatformCredentialSerializer();

  @override
  final Table table = Table(Tables.platformCredential, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.int(Keys.platformId)
        .references(Tables.platform, onDelete: OnAction.cascade),
    Column.text(Keys.username)
        .check("length(${Keys.username}) between 1 and 80"),
    Column.text(Keys.password)
        .check("length(${Keys.password}) between 1 and 80")
  ]);
}
