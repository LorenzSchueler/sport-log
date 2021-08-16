
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/wod/wod_table.dart';
import 'package:sport_log/models/wod/wod.dart';

part 'wod_dao.g.dart';

@UseDao(tables: [Wods])
class WodDao extends DatabaseAccessor<Database> with _$WodDaoMixin {
  WodDao(Database attachedDatabase) : super(attachedDatabase);

  Future<Result<void, DbException>> createWod(Wod wod) async {
    if (!wod.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await into(wods).insert(wod);
    return Success(null);
  }

  Future<void> deleteWod(Int64 id) async {
    await (update(wods)
      ..where((wod) => wod.id.equals(id.toInt()) & wod.deleted.not())
    ).write(const WodsCompanion(deleted: Value(true)));
  }

  Future<Result<void, DbException>> updateWod(Wod wod) async {
    if (!wod.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await (update(wods)
      ..where((w) => w.id.equals(wod.id.toInt()) & w.deleted.not())
    ).write(wod);
    return Success(null);
  }

  Future<List<Wod>> getAllWods() async {
    return (select(wods)
        ..where((wod) => wod.deleted.not())).get();
  }
}
