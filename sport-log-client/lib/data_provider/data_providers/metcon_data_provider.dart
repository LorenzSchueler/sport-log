import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconDataProvider extends DataProvider<MetconDescription> {
  final metconApi = Api.instance.metcons;
  final metconMovementApi = Api.instance.metconMovements;

  final metconDb = AppDatabase.instance!.metcons;
  final metconMovementDb = AppDatabase.instance!.metconMovements;
  final movementDb = AppDatabase.instance!.movements;
  final metconSessionDb = AppDatabase.instance!.metconSessions;

  @override
  Future<void> createSingle(MetconDescription object) async {
    assert(object.isValid());
    // TODO: catch errors
    await metconDb.createSingle(object.metcon);
    await metconMovementDb.createMultiple(object.moves);
    metconApi.postFull(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        metconDb.setSynchronized(object.metcon.id);
        metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
      }
    });
  }

  @override
  Future<void> deleteSingle(MetconDescription object) async {
    // TODO: catch errors
    await metconDb.deleteSingle(object.metcon.id);
    await metconMovementDb.deleteByMetcon(object.metcon.id);
    metconApi.deleteFull(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        metconDb.setSynchronized(object.metcon.id);
        metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
      }
    });
  }

  @override
  Future<List<MetconDescription>> getNonDeleted() async {
    final metcons = await metconDb.getNonDeleted();
    return Future.wait(metcons
        .map((metcon) async => MetconDescription(
            metcon: metcon,
            moves: await metconMovementDb.getByMetcon(metcon.id),
            hasReference: await metconSessionDb.existsByMetcon(metcon.id)))
        .toList());
  }

  @override
  Future<void> pushToServer() async {
    await Future.wait([
      _pushUpdatedToServer(),
      _pushCreatedToServer(),
    ]);
  }

  Future<void> _pushUpdatedToServer() async {
    final metconsToUpdate =
        await metconDb.getWithSyncStatus(SyncStatus.updated);
    final apiResult1 = await metconApi.putMultiple(metconsToUpdate);
    if (apiResult1.isFailure) {
      handleApiError(apiResult1.failure);
      return;
    }
    metconDb.setAllUpdatedSynchronized();

    final metconMovementsToUpdate =
        await metconMovementDb.getWithSyncStatus(SyncStatus.updated);
    final apiResult2 =
        await metconMovementApi.putMultiple(metconMovementsToUpdate);
    if (apiResult2.isFailure) {
      handleApiError(apiResult2.failure);
      return;
    }
    metconMovementDb.setAllUpdatedSynchronized();
  }

  Future<void> _pushCreatedToServer() async {
    final metconsToCreate =
        await metconDb.getWithSyncStatus(SyncStatus.created);
    final apiResult1 = await metconApi.postMultiple(metconsToCreate);
    if (apiResult1.isFailure) {
      handleApiError(apiResult1.failure);
      return;
    }
    metconDb.setAllCreatedSynchronized();

    final metconMovementsToCreate =
        await metconMovementDb.getWithSyncStatus(SyncStatus.created);
    final apiResult2 =
        await metconMovementApi.postMultiple(metconMovementsToCreate);
    if (apiResult2.isFailure) {
      handleApiError(apiResult2.failure);
      return;
    }
    metconMovementDb.setAllCreatedSynchronized();
  }

  @override
  Future<void> updateSingle(MetconDescription object) async {
    assert(object.isValid());

    // update db
    // TODO: use transaction

    await metconDb.updateSingle(object.metcon);

    final oldMetconMovements =
        await metconMovementDb.getByMetcon(object.metcon.id);
    final oldIds = oldMetconMovements.map((mm) => mm.id).toList();
    final newIds = object.moves.map((mm) => mm.id).toList();
    List<MetconMovement> toCreate = [], toUpdate = [], toDelete = [];

    // TODO: use faster algorithm
    for (final newMetconMovement in object.moves) {
      oldIds.contains(newMetconMovement.id)
          ? toUpdate.add(newMetconMovement)
          : toCreate.add(newMetconMovement);
    }
    for (final oldMetconMovement in oldMetconMovements) {
      if (!newIds.contains(oldMetconMovement.id)) {
        toDelete.add(oldMetconMovement);
      }
    }

    await Future.wait([
      metconMovementDb.updateMultiple(toUpdate),
      metconMovementDb.deleteMultiple(toDelete.map((mm) => mm.id).toList()),
      metconMovementDb.createMultiple(toCreate),
    ]);

    // update server

    final result1 = await metconApi.putSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    } else {
      metconDb.setSynchronized(object.metcon.id);
    }
    final result2 = await metconMovementApi.putMultiple(toUpdate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    final result3 = await metconMovementApi.putMultiple(toDelete);
    if (result3.isFailure) {
      handleApiError(result3.failure);
      return;
    }
    final result4 = await metconMovementApi.postMultiple(toCreate);
    if (result4.isFailure) {
      handleApiError(result4.failure);
      return;
    }
    metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
  }
}
