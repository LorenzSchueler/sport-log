import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends TableAccessor<Platform> {
  @override
  DbSerializer<Platform> get serde => DbPlatformSerializer();

  @override
  final Table table = Table(Tables.platform, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus).withDefault('2').checkIn(<int>[0, 1, 2]),
    Column.text(Columns.name).checkLengthBetween(3, 80),
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
    Column.int(Columns.syncStatus).withDefault('2').checkIn(<int>[0, 1, 2]),
    Column.int(Columns.userId),
    Column.int(Columns.platformId)
        .references(Tables.platform, onDelete: OnAction.cascade),
    Column.text(Columns.username).checkLengthBetween(1, 80),
    Column.text(Columns.password).checkLengthBetween(1, 80),
  ]);
}
