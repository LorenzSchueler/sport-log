import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/helpers/logger.dart';
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
  final _metconApi = Api.metcons;
  final _metconMovementApi = Api.metconMovements;

  final _metconDb = AppDatabase.metcons;
  final _metconMovementDb = AppDatabase.metconMovements;
  final _movementDb = AppDatabase.movements;
  final _metconSessionDb = AppDatabase.metconSessions;

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
    await _metconDb.createSingle(object.metcon);
    await _metconMovementDb
        .createMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    notifyListeners();
    final result1 = await _metconApi.postSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    _metconDb.setSynchronized(object.metcon.id);
    final result2 = await Api.metconMovements
        .postMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    _metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
    return true;
  }

  @override
  Future<bool> updateSingle(MetconDescription object) async {
    assert(object.isValid());

    final oldMMovements = await _metconMovementDb.getByMetcon(object.metcon.id);
    final newMMovements = [...object.moves.map((m) => m.metconMovement)];

    final diffing = diff(oldMMovements, newMMovements);

    await _metconDb.updateSingle(object.metcon);
    await _metconMovementDb.deleteMultiple(diffing.toDelete);
    await _metconMovementDb.updateMultiple(diffing.toUpdate);
    await _metconMovementDb.createMultiple(diffing.toCreate);
    notifyListeners();

    final result1 = await _metconApi.putSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    _metconDb.setSynchronized(object.metcon.id);

    for (final mm in diffing.toDelete) {
      mm.deleted = true;
    }
    final result2 = await _metconMovementApi
        .putMultiple(diffing.toDelete + diffing.toUpdate);
    final result3 = await _metconMovementApi.postMultiple(diffing.toCreate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    if (result3.isFailure) {
      handleApiError(result3.failure);
      return false;
    }
    _metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
    return true;
  }

  @override
  Future<bool> deleteSingle(MetconDescription object) async {
    object.setDeleted();
    // TODO: catch errors
    await _metconMovementDb.deleteByMetcon(object.metcon.id);
    await _metconDb.deleteSingle(object.metcon.id);
    notifyListeners();
    // TODO: server deletes metcon movements automatically
    final result1 = await _metconApi.putSingle(object.metcon);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    _metconDb.setSynchronized(object.metcon.id);
    final result2 = await _metconMovementApi
        .putMultiple(object.moves.map((mmd) => mmd.metconMovement).toList());
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    _metconMovementDb.setSynchronizedByMetcon(object.metcon.id);
    return true;
  }

  @override
  Future<List<MetconDescription>> getNonDeleted() async {
    return Future.wait(
      (await _metconDb.getNonDeleted())
          .map(
            (metcon) async => MetconDescription(
              metcon: metcon,
              moves: await _getMmdByMetcon(metcon.id),
              hasReference: await _metconSessionDb.existsByMetcon(metcon.id),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> pushUpdatedToServer() async {
    final metconsToUpdate =
        await _metconDb.getWithSyncStatus(SyncStatus.updated);
    final apiResult1 = await _metconApi.putMultiple(metconsToUpdate);
    if (apiResult1.isFailure) {
      handleApiError(apiResult1.failure);
      return;
    }
    _metconDb.setAllUpdatedSynchronized();

    final metconMovementsToUpdate =
        await _metconMovementDb.getWithSyncStatus(SyncStatus.updated);
    final apiResult2 =
        await _metconMovementApi.putMultiple(metconMovementsToUpdate);
    if (apiResult2.isFailure) {
      handleApiError(apiResult2.failure);
      return;
    }
    _metconMovementDb.setAllUpdatedSynchronized();
  }

  @override
  Future<void> pushCreatedToServer() async {
    final metconsToCreate =
        await _metconDb.getWithSyncStatus(SyncStatus.created);
    final apiResult1 = await _metconApi.postMultiple(metconsToCreate);
    if (apiResult1.isFailure) {
      handleApiError(apiResult1.failure);
      return;
    }
    _metconDb.setAllCreatedSynchronized();

    final metconMovementsToCreate =
        await _metconMovementDb.getWithSyncStatus(SyncStatus.created);
    final apiResult2 =
        await _metconMovementApi.postMultiple(metconMovementsToCreate);
    if (apiResult2.isFailure) {
      handleApiError(apiResult2.failure);
      return;
    }
    _metconMovementDb.setAllCreatedSynchronized();
  }

  @override
  Future<void> pullFromServer() async {
    final result1 = await _metconApi.getMultiple();
    if (result1.isFailure) {
      handleApiError(result1.failure);
      throw result1.failure;
    }
    await _metconDb.upsertMultiple(result1.success, synchronized: true);

    final result2 = await _metconMovementApi.getMultiple();
    if (result2.isFailure) {
      handleApiError(result2.failure);
      notifyListeners();
      throw result2.failure;
    }
    await _metconMovementDb.upsertMultiple(result2.success, synchronized: true);
    notifyListeners();
  }

  Future<List<MetconMovementDescription>> _getMmdByMetcon(Int64 id) async {
    final metconMovements = await _metconMovementDb.getByMetcon(id);
    return Future.wait(
      metconMovements
          .map(
            (mm) async => MetconMovementDescription(
              metconMovement: mm,
              movement: (await _movementDb.getSingle(mm.movementId))!,
            ),
          )
          .toList(),
    );
  }

  Future<MetconDescription?> getById(Int64 id) async {
    final metcon = await _metconDataProvider.getById(id);
    if (metcon == null) {
      return null;
    }
    return MetconDescription(
      metcon: metcon,
      moves: await _getMmdByMetcon(metcon.id),
      hasReference: await _metconSessionDb.existsByMetcon(metcon.id),
    );
  }
}

class MetconSessionDescriptionDataProvider
    extends DataProvider<MetconSessionDescription> {
  final _metconSessionDb = AppDatabase.metconSessions;

  final _metconSessionDataProvider = MetconSessionDataProvider.instance;
  final _metconDataProvider = MetconDataProvider.instance;
  final _metconMovementDataProvider = MetconMovementDataProvider.instance;
  final _movementDataProvider = MovementDataProvider.instance;
  final _metconDescriptionDataProvider =
      MetconDescriptionDataProvider.instance; // don't forward notifications

  MetconSessionDescriptionDataProvider._();
  static MetconSessionDescriptionDataProvider? _instance;
  static MetconSessionDescriptionDataProvider get instance {
    if (_instance == null) {
      _instance = MetconSessionDescriptionDataProvider._();
      _instance!._metconSessionDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._metconDataProvider.addListener(_instance!.notifyListeners);
      _instance!._metconMovementDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._movementDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<bool> createSingle(MetconSessionDescription object) async {
    return await _metconSessionDataProvider.createSingle(object.metconSession);
  }

  @override
  Future<bool> updateSingle(MetconSessionDescription object) async {
    return await _metconSessionDataProvider.updateSingle(object.metconSession);
  }

  @override
  Future<bool> deleteSingle(MetconSessionDescription object) async {
    return await _metconSessionDataProvider.deleteSingle(object.metconSession);
  }

  @override
  Future<List<MetconSessionDescription>> getNonDeleted() async {
    return await _mapToDescription(
      await _metconSessionDataProvider.getNonDeleted(),
    );
  }

  @override
  Future<void> pullFromServer() async {
    await _movementDataProvider.pullFromServer();
    await _metconDataProvider.pullFromServer();
    await _metconMovementDataProvider.pullFromServer();
    await _metconSessionDataProvider.pullFromServer();
  }

  @override
  Future<void> pushCreatedToServer() async {
    await _metconSessionDataProvider.pushCreatedToServer();
  }

  @override
  Future<void> pushUpdatedToServer() async {
    await _metconSessionDataProvider.pushUpdatedToServer();
  }

  Future<List<MetconSessionDescription>> getByTimerangeAndMovement({
    Int64? movementId,
    DateTime? from,
    DateTime? until,
  }) async {
    return await _mapToDescription(
      await _metconSessionDb.getByTimerangeAndMovement(
        from: from,
        until: until,
        movementIdValue: movementId,
      ),
    );
  }

  Future<List<MetconSessionDescription>> _mapToDescription(
    List<MetconSession> metconSessions,
  ) async {
    return Future.wait(
      metconSessions
          .map(
            (session) async => MetconSessionDescription(
              metconSession: session,
              metconDescription: (await _metconDescriptionDataProvider
                  .getById(session.metconId))!,
            ),
          )
          .toList(),
    );
  }
}
