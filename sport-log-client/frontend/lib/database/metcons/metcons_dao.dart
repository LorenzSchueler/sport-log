
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/metcons/metcon_tables.dart';
import 'package:sport_log/models/metcon/all.dart';

part 'metcons_dao.g.dart';

@UseDao(
  tables: [Metcons, MetconMovements, MetconSessions],
  include: {'metcons.moor'}
)
class MetconsDao extends DatabaseAccessor<Database> with _$MetconsDaoMixin {
  MetconsDao(Database attachedDatabase) : super(attachedDatabase);

  // select methods


  // creation methods

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


  // deletion methods

  Future<Result<void, DbException>> deleteMetcon(Int64 id) async {
    if (await metconHasMetconSession(id.toInt()).getSingleOrNull() != null) {
      // there is still a metcon session left
      return Failure(DbException.metconHasMetconSession);
    }
    return transaction(() async {
      await deleteMetconMovementsOfMetcon(id);
      await _unsafeDeleteMetcon(id);
      return Success(null);
    });
  }

  Future<void> deleteMetconMovementsOfMetcon(Int64 id) async {
    (update(metconMovements)
      ..where((mm) => mm.metconId.equals(id.toInt()) & mm.deleted.equals(false))
    ).write(const MetconMovementsCompanion(deleted: Value(true)));
  }

  Future<void> _unsafeDeleteMetcon(Int64 id) async {
    (update(metcons)
      ..where((m) => m.id.equals(id.toInt()) & m.deleted.equals(false))
    ).write(const MetconsCompanion(deleted: Value(true)));
  }

  Future<void> deleteMetconSession(Int64 id) async {
    (update(metconSessions)
      ..where((ms) => ms.id.equals(id.toInt()) & ms.deleted.equals(false))
    ).write(const MetconSessionsCompanion(deleted: Value(true)));
  }


  // update methods
}