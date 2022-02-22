import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
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
  final metconApi = Api.metcons;
  final metconMovementApi = Api.metconMovements;

  final metconDb = AppDatabase.metcons;
  final metconMovementDb = AppDatabase.metconMovements;
  final movementDb = AppDatabase.movements;
  final metconSessionDb = AppDatabase.metconSessions;

  final _metconDataProvider = MetconDataProvider.instance;
  final _metconMovementDataProvider = MetconMovementDataProvider.instance;
  final _movementDataProvider = MovementDataProvider.instance;

  MetconDescriptionDataProvider._();
  static MetconDescriptionDataProvider? _instance;
  static MetconDescriptionDataProvider get instance {
    if (_instance == null) {
      _instance = MetconDescriptionDataProvider._();
      _instance!._metconDataProvider.addListener(_instance!.notifyListeners);
      _instance!._metconMovementDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._movementDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<bool> createSingle(MetconDescription object) async {
    assert(object.isValid());
    // TODO: catch errors
    await metconDb.createSingle(object.metcon);
    await metconMovementDb
        .createMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    notifyListeners();
    final result1 = await metconApi.postSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    metconDb.setSynchronized(object.metcon.id);
    final result2 = await Api.metconMovements
        .postMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
    return true;
  }

  @override
  Future<bool> updateSingle(MetconDescription object) async {
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
      return false;
    }
    metconDb.setSynchronized(object.id);

    for (final mm in diffing.toDelete) {
      mm.deleted = true;
    }
    final result2 = await metconMovementApi
        .putMultiple(diffing.toDelete + diffing.toUpdate);
    final result3 = await metconMovementApi.postMultiple(diffing.toCreate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    if (result3.isFailure) {
      handleApiError(result3.failure);
      return false;
    }
    metconMovementDb.setSynchronizedByMetcon(object.id);
    return true;
  }

  @override
  Future<bool> deleteSingle(MetconDescription object) async {
    object.setDeleted();
    // TODO: catch errors
    await metconMovementDb.deleteByMetcon(object.metcon.id);
    await metconDb.deleteSingle(object.metcon.id);
    notifyListeners();
    // TODO: server deletes metcon movements automatically
    final result1 = await metconApi.putSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    metconDb.setSynchronized(object.metcon.id);
    final result2 = await metconMovementApi
        .putMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
    return true;
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
  Future<void> pushUpdatedToServer() async {
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

  @override
  Future<void> pushCreatedToServer() async {
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
  Future<void> pullFromServer() async {
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

  Future<List<MetconMovementDescription>> _getMmdByMetcon(Int64 id) async {
    final metconMovements = await metconMovementDb.getByMetcon(id);
    return Future.wait(metconMovements
        .map((mm) async => MetconMovementDescription(
            metconMovement: mm,
            movement: (await movementDb.getSingle(mm.movementId))!))
        .toList());
  }
}
