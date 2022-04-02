import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodTable extends TableAccessor<Wod> {
  @override
  DbSerializer<Wod> get serde => DbWodSerializer();

  @override
  final Table table = Table(
    name: Tables.wod,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.int(Columns.userId),
      Column.text(Columns.date),
      Column.text(Columns.description)..nullable()
    ],
    uniqueColumns: [
      [Columns.date]
    ],
  );

  @override
  Future<List<Wod>> getNonDeleted() async {
    final result = await database.query(
      tableName,
      where: notDeleted,
      orderBy: orderByDate,
    );
    return result.map(serde.fromDbRecord).toList();
  }
}
