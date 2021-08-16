
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/diary/diary.dart';

import 'diary_table.dart';

part 'diary_dao.g.dart';

@UseDao(tables: [Diaries])
class DiaryDao extends DatabaseAccessor<Database> with _$DiaryDaoMixin {
  DiaryDao(Database attachedDatabase) : super(attachedDatabase);

  Future<Result<void, DbException>> createDiary(Diary diary) async {
    if (!diary.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await into(diaries).insert(diary);
    return Success(null);
  }

  Future<void> deleteDiary(Int64 id) async {
    await (update(diaries)
      ..where((diary) => diary.id.equals(id.toInt()) & diary.deleted.not())
    ).write(const DiariesCompanion(deleted: Value(true)));
  }

  Future<Result<void, DbException>> updateDiary(Diary diary) async {
    if (!diary.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await (update(diaries)
      ..where((d) => d.id.equals(diary.id.toInt()) & d.deleted.not())
    ).write(diary);
    return Success(null);
  }

  Future<List<Diary>> getAllDiaries() async {
    return (select(diaries)
        ..where((d) => d.deleted.not())).get();
  }
}
