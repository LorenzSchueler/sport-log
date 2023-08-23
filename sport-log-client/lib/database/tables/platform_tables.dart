import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformTable extends TableAccessor<Platform> {
  factory PlatformTable() => _instance;

  PlatformTable._();

  static final _instance = PlatformTable._();

  @override
  DbSerializer<Platform> get serde => DbPlatformSerializer();

  @override
  final Table table = Table(
    name: Tables.platform,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.text(Columns.name)..checkLengthBetween(2, 80),
      Column.bool(Columns.credential),
    ],
    uniqueColumns: [
      [Columns.name],
    ],
  );
}

class PlatformCredentialTable extends TableAccessor<PlatformCredential> {
  factory PlatformCredentialTable() => _instance;

  PlatformCredentialTable._();

  static final _instance = PlatformCredentialTable._();

  @override
  DbSerializer<PlatformCredential> get serde =>
      DbPlatformCredentialSerializer();

  @override
  final Table table = Table(
    name: Tables.platformCredential,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.platformId)
        ..references(Tables.platform, onDelete: OnAction.cascade),
      Column.text(Columns.username)..checkLengthLe(80),
      Column.text(Columns.password)..checkLengthLe(80),
    ],
    uniqueColumns: [
      [Columns.platformId],
    ],
  );

  Future<PlatformCredential?> getByPlatform(Platform platform) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        "${Columns.platformId} = ?",
      ]),
      whereArgs: [platform.id.toInt()],
    );
    if (records.isEmpty) {
      return null;
    }
    return serde.fromDbRecord(records[0]);
  }
}
