
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

  Future<List<MetconDescription>> getAllMetcons() async {
    final List<Metcon> metconsList = await (select(metcons)
      ..where((m) => m.deleted.equals(false))
    ).get();
    return Future.wait(metconsList.map((m) async {
      return MetconDescription(
          metcon: m,
          moves: await _getMetconMovementsOfMetcon(m.id),
      );
    }));
  }

  Future<List<MetconMovement>> _getMetconMovementsOfMetcon(
      Int64 id) async {
    return await (select(metconMovements)
      ..where((mm) => mm.metconId.equals(id.toInt()) & mm.deleted.equals(false))
    ).get();
  }

  Future<bool> metconMovementWithMovementExists(Int64 id) async {
    return await _metconMovementWithMovementExists(id.toInt())
        .getSingleOrNull() != null;
  }

  // creation methods

  Future<Result<void, DbException>> createMetcon(
      MetconDescription metconDescription) async {
    if (!metconDescription.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    return transaction(() async {
      await into(metcons).insert(metconDescription.metcon);
      await batch((batch) {
        batch.insertAll(metconMovements, metconDescription.moves);
      });
      return Success(null);
    });
  }

  Future<Result<void, DbException>> createMetconSession(
      MetconSession metconSession) async {
    if (!metconSession.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    if (!await metconExists(metconSession.metconId)) {
      return Failure(DbException.doesNotExist);
    }
    await into(metconSessions).insert(metconSession);
    return Success(null);
  }

  Future<bool> metconExists(Int64 id) async {
    return await _metconExists(id.toInt()).getSingleOrNull() != null;
  }


  // deletion methods

  Future<void> deleteMetcon(Int64 id) async {
    return transaction(() async {
      await _deleteMetconMovementsOfMetcon(id);
      await _unsafeDeleteMetcon(id);
    });
  }

  Future<void> _deleteMetconMovementsOfMetcon(Int64 id) async {
    await (update(metconMovements)
      ..where((mm) => mm.metconId.equals(id.toInt()) & mm.deleted.equals(false))
    ).write(const MetconMovementsCompanion(deleted: Value(true)));
  }

  Future<void> _unsafeDeleteMetcon(Int64 id) async {
    await (update(metcons)
      ..where((m) => m.id.equals(id.toInt()) & m.deleted.equals(false))
    ).write(const MetconsCompanion(deleted: Value(true)));
  }

  Future<void> deleteMetconSession(Int64 id) async {
    await (update(metconSessions)
      ..where((ms) => ms.id.equals(id.toInt()) & ms.deleted.equals(false))
    ).write(const MetconSessionsCompanion(deleted: Value(true)));
  }


  // update methods

  Future<Result<void, DbException>> updateMetconSession(MetconSession metconSession) async {
    if (!metconSession.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    if (!await metconExists(metconSession.metconId)) {
      return Failure(DbException.doesNotExist);
    }
    await (update(metconSessions)
      ..where((ms) => ms.id.equals(metconSession.id.toInt())
        & ms.deleted.equals(false))
    ).write(metconSession);
    return Success(null);
  }

  Future<Result<void, DbException>> updateMetcon(MetconDescription metconDescription) async {
    if (!metconDescription.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    // starting a transaction for consistency
    return transaction(() async {
      // updating the metcon record
      await (update(metcons)
        ..where((m) => m.id.equals(metconDescription.metcon.id.toInt())
          & m.deleted.equals(false))
      ).write(metconDescription.metcon);

      // find all metcon movement ids of the former metcon
      final oldMetconMovementsIds = (await _idsOfMetconMovementsOfMetcon(
          metconDescription.metcon.id.toInt()).get())
          .map((id) => id.toInt())
          .toSet();
      List<MetconMovement> toCreate =  [];
      List<MetconMovement> toUpdate = [];
      // find out which metcon movements need to be updated or created
      for (final mm in metconDescription.moves) {
        if (!oldMetconMovementsIds.contains(mm.id.toInt())) {
          toCreate.add(mm);
        } else {
          toUpdate.add(mm);
        }
      }
      // all metcons that didn't get reused will be deleted
      Set<int> toDelete = oldMetconMovementsIds.difference(
          toUpdate.map((mm) => mm.id.toInt()).toSet());

      // starting a batch for faster execution
      await batch((batch) async {
        // deleting all metcon movements in toDelete
        for (int id in toDelete) {
          batch.update(
            metconMovements,
            const MetconMovementsCompanion(deleted: Value(true)),
            where: ($MetconMovementsTable mm) =>
                mm.id.equals(id) & mm.deleted.not()
          );
        }

        // updating all metcon movements in toUpdate
        for (final metconMovement in toUpdate) {
          batch.update(
            metconMovements,
            metconMovement,
            where: ($MetconMovementsTable mm) =>
                mm.id.equals(metconMovement.id.toInt()) & mm.deleted.not()
          );
        }

        // inserting all metcon movements in toCreate
        batch.insertAll(metconMovements, toCreate);
      });

      return Success(null);
    });
  }
}