import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/diary/diary.dart';

class DiaryTable extends TableAccessor<Diary> {
  factory DiaryTable() => _instance;

  DiaryTable._();

  static final _instance = DiaryTable._();

  @override
  DbSerializer<Diary> get serde => DbDiarySerializer();

  @override
  final Table table = Table(
    name: Tables.diary,
    columns: [
      Column.int(Columns.id)..primaryKey(),
      Column.bool(Columns.deleted)..withDefault('0'),
      Column.int(Columns.syncStatus)
        ..withDefault('2')
        ..checkIn(<int>[0, 1, 2]),
      Column.text(Columns.date),
      Column.real(Columns.bodyweight)
        ..nullable()
        ..checkGt(0),
      Column.text(Columns.comments)..nullable(),
    ],
    uniqueColumns: [
      [Columns.date],
    ],
  );

  @override
  Future<List<Diary>> getNonDeleted() async {
    final records = await database.query(
      tableName,
      where: notDeleted,
      orderBy: orderByDate,
    );
    return records.map(serde.fromDbRecord).toList();
  }

  Future<List<Diary>> getByTimerangeAndComment(
    DateTime? from,
    DateTime? until,
    String? comment,
  ) async {
    final records = await database.query(
      tableName,
      where: TableAccessor.combineFilter([
        notDeleted,
        fromFilter(from, dateOnly: true),
        untilFilter(until, dateOnly: true),
        commentFilter(comment),
      ]),
      orderBy: orderByDate,
    );
    return records.map(serde.fromDbRecord).toList();
  }
}
