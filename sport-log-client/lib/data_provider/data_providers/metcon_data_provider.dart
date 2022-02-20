import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconDataProvider extends EntityDataProvider<Metcon> {
  static final instance = MetconDataProvider._();
  MetconDataProvider._();

  @override
  final Api<Metcon> api = Api.metcons;

  @override
  final TableAccessor<Metcon> db = AppDatabase.metcons;

  @override
  List<Metcon> getFromAccountData(AccountData accountData) =>
      accountData.metcons;
}

class MetconMovementDataProvider extends EntityDataProvider<MetconMovement> {
  static final instance = MetconMovementDataProvider._();
  MetconMovementDataProvider._();

  @override
  final Api<MetconMovement> api = Api.metconMovements;

  @override
  final TableAccessor<MetconMovement> db = AppDatabase.metconMovements;

  @override
  List<MetconMovement> getFromAccountData(AccountData accountData) =>
      accountData.metconMovements;
}

class MetconSessionDataProvider extends EntityDataProvider<MetconSession> {
  static final instance = MetconSessionDataProvider._();
  MetconSessionDataProvider._();

  @override
  final Api<MetconSession> api = Api.metconSessions;

  @override
  final TableAccessor<MetconSession> db = AppDatabase.metconSessions;

  @override
  List<MetconSession> getFromAccountData(AccountData accountData) =>
      accountData.metconSessions;
}

class MetconDescriptionDataProvider extends DataProvider<MetconDescription> {
  static final instance = MetconDescriptionDataProvider._();
  MetconDescriptionDataProvider._();

  final metconApi = Api.metcons;
  final metconMovementApi = Api.metconMovements;

  final metconDb = AppDatabase.metcons;
  final metconMovementDb = AppDatabase.metconMovements;
  final movementDb = AppDatabase.movements;
  final metconSessionDb = AppDatabase.metconSessions;

  @override
  Future<void> createSingle(MetconDescription object) async {
    assert(object.isValid());
    // TODO: catch errors
    await metconDb.createSingle(object.metcon);
    await metconMovementDb
        .createMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    notifyListeners();
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
    await metconMovementDb.deleteByMetcon(object.metcon.id);
    await metconDb.deleteSingle(object.metcon.id);
    notifyListeners();
    // TODO: server deletes metcon movements automatically
    metconApi.deleteFull(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        metconDb.setSynchronized(object.metcon.id);
        metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
      }
    });
  }

  Future<List<MetconMovementDescription>> _getMmdByMetcon(Int64 id) async {
    final metconMovements = await metconMovementDb.getByMetcon(id);
    return Future.wait(metconMovements
        .map((mm) async => MetconMovementDescription(
            metconMovement: mm,
            movement: (await movementDb.getSingle(mm.movementId))!))
        .toList());
  }

  @override
  Future<List<MetconDescription>> getNonDeleted() async {
    final metcons = await metconDb.getNonDeleted();
    return Future.wait(metcons
        .map((metcon) async => MetconDescription(
            metcon: metcon,
            moves: await _getMmdByMetcon(metcon.id),
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

    final oldMMovements = await metconMovementDb.getByMetcon(object.id);
    final newMMovements = [...object.moves.map((m) => m.metconMovement)];

    final diffing = diff(oldMMovements, newMMovements);

    await metconDb.updateSingle(object.metcon);
    await metconMovementDb.deleteMultiple(diffing.toDelete);
    await metconMovementDb.updateMultiple(diffing.toUpdate);
    await metconMovementDb.createMultiple(diffing.toCreate);
    notifyListeners();

    final result1 = await metconApi.putSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    metconDb.setSynchronized(object.id);

    for (final mm in diffing.toDelete) {
      mm.deleted = true;
    }
    final result2 = await metconMovementApi
        .putMultiple(diffing.toDelete + diffing.toUpdate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
    }

    final result3 = await metconMovementApi.postMultiple(diffing.toCreate);
    if (result3.isFailure) {
      handleApiError(result3.failure);
      return;
    }
    metconMovementDb.setSynchronizedByMetcon(object.id);
  }

  @override
  Future<void> doFullUpdate() async {
    final result1 = await metconApi.getMultiple();
    if (result1.isFailure) {
      handleApiError(result1.failure);
      throw result1.failure;
    }
    await metconDb.upsertMultiple(result1.success, synchronized: true);

    final result2 = await metconMovementApi.getMultiple();
    if (result2.isFailure) {
      handleApiError(result2.failure);
      notifyListeners();
      throw result2.failure;
    }
    await metconMovementDb.upsertMultiple(result2.success, synchronized: true);
    notifyListeners();
  }

  @override
  Future<void> upsertFromAccountData(AccountData accountData) async {
    await metconDb.upsertMultiple(accountData.metcons, synchronized: true);
    await metconMovementDb.upsertMultiple(accountData.metconMovements,
        synchronized: true);
    notifyListeners();
  }
}
