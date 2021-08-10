
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/metcon/metcon_tables.dart';
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

  Future<void> createMetcon(MetconDescription metconDescription) async {
    // TODO: consistency check: verify metcon, check if movements exist
    return transaction(() async {
      await into(metcons).insert(metconDescription.metcon);
      await batch((batch) {
        batch.insertAll(metconMovements, metconDescription.moves);
      });
    });
  }

  Future<Result<void, DbException>> createMetconSession(MetconSession metconSession) async {
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
