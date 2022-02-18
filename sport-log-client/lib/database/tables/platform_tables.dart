import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends TableAccessor<Platform> {
  @override
  DbSerializer<Platform> get serde => DbPlatformSerializer();

  @override
  final Table table = Table(Tables.platform, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.text(Columns.name).check("length(${Columns.name}) between 3 and 80"),
  ]);
}

class PlatformCredentialTable extends TableAccessor<PlatformCredential> {
  @override
  DbSerializer<PlatformCredential> get serde =>
      DbPlatformCredentialSerializer();

  @override
  final Table table = Table(Tables.platformCredential, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus)
        .withDefault('2')
        .check('${Columns.syncStatus} IN (0, 1, 2)'),
    Column.int(Columns.userId),
    Column.int(Columns.platformId)
        .references(Tables.platform, onDelete: OnAction.cascade),
    Column.text(Columns.username)
        .check("length(${Columns.username}) between 1 and 80"),
    Column.text(Columns.password)
        .check("length(${Columns.password}) between 1 and 80")
  ]);
}
