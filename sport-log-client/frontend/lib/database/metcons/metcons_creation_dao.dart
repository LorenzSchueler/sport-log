
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/metcons/metcon_tables.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';

part 'metcons_creation_dao.g.dart';

@UseDao(
  tables: [Metcons, MetconMovements, MetconSessions],
  include: {'metcons.moor'}
)
class MetconsCreationDao extends DatabaseAccessor<Database> with _$MetconsCreationDaoMixin {
  MetconsCreationDao(Database attachedDatabase) : super(attachedDatabase);

  Future<Result<void, DbException>> createMetcon(MetconDescription metconDescription) async {
    if (!metconDescription.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    // TODO: check if all movement ids of metcon movements are valid
    return transaction(() async {
      await into(metcons).insert(metconDescription.metcon);
      await batch((batch) {
        batch.insertAll(metconMovements, metconDescription.moves);
      });
      return Success(null);
    });
  }

  Future<Result<void, DbException>> createMetconSession(MetconSession metconSession) async {
    if (!metconSession.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    if (!await metconExists(metconSession.metconId)) {
      return Failure(DbException.metconDoesNotExist);
    }
    into(metconSessions).insert(metconSession);
    return Success(null);
  }

  Future<bool> metconExists(Int64 id) async {
    return await _metconExists(id.toInt()).getSingleOrNull() != null;
  }
}
