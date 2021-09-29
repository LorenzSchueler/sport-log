import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthDataProvider extends DataProvider<StrengthSessionDescription> {
  final strengthSessionDb = AppDatabase.instance!.strengthSessions;
  final strengthSetDb = AppDatabase.instance!.strengthSets;
  final movementDb = AppDatabase.instance!.movements;

  final strengthSessionApi = Api.instance.strengthSessions;
  final strengthSetApi = Api.instance.strengthSets;

  static final instance = StrengthDataProvider._();
  StrengthDataProvider._();

  @override
  Future<void> createSingle(StrengthSessionDescription object) async {
    assert(object.isValid());
    // TODO: catch errors
    await strengthSessionDb.createSingle(object.strengthSession);
    await strengthSetDb.createMultiple(object.strengthSets!);
    notifyListeners();
    final result1 = await strengthSessionApi.postSingle(object.strengthSession);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSessionDb.setSynchronized(object.id);
    final result2 = await strengthSetApi.postMultiple(object.strengthSets!);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    strengthSetDb.setSynchronizedByStrengthSession(object.id);
  }

  @override
  Future<void> deleteSingle(StrengthSessionDescription object) async {
    assert(object.strengthSets != null);
    object.setDeleted();
    // TODO: catch errors
    await strengthSetDb.deleteByStrengthSession(object.id);
    await strengthSessionDb.deleteSingle(object.id);
    notifyListeners();
    // TODO: server deletes strength sets automatically
    final result1 = await strengthSetApi.putMultiple(object.strengthSets!);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSetDb.setSynchronizedByStrengthSession(object.id);
    final result2 = await strengthSessionApi.putSingle(object.strengthSession);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    strengthSessionDb.setSynchronized(object.id);
  }

  @override
  Future<void> doFullUpdate() async {
    final result1 = await strengthSessionApi.getMultiple();
    if (result1.isFailure) {
      handleApiError(result1.failure);
      throw result1.failure;
    }
    await strengthSessionDb.upsertMultiple(result1.success, synchronized: true);

    final result2 = await strengthSetApi.getMultiple();
    if (result2.isFailure) {
      notifyListeners();
      handleApiError(result2.failure);
      throw result2.failure;
    }
    strengthSetDb
        .upsertMultiple(result2.success, synchronized: true)
        .then((_) => notifyListeners());
  }

  @override
  Future<List<StrengthSessionDescription>> getNonDeleted() async {
    return (await strengthSessionDb.getSessionDescriptions());
  }

  Future<List<StrengthSet>> getStrengthSetsByStrengthSession(Int64 id) {
    return strengthSetDb.getByStrengthSession(id);
  }

  @override
  Future<void> pushToServer() async {
    await Future.wait([
      _pushUpdatedToServer(),
      _pushCreatedToServer(),
    ]);
  }

  Future<void> _pushUpdatedToServer() async {
    final sessionsToUpdate =
        await strengthSessionDb.getWithSyncStatus(SyncStatus.updated);
    final result1 = await strengthSessionApi.putMultiple(sessionsToUpdate);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSessionDb.setAllUpdatedSynchronized();

    final setsToUpdate =
        await strengthSetDb.getWithSyncStatus(SyncStatus.updated);
    final result2 = await strengthSetApi.putMultiple(setsToUpdate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    strengthSetDb.setAllUpdatedSynchronized();
  }

  Future<void> _pushCreatedToServer() async {
    final sessionsToCreate =
        await strengthSessionDb.getWithSyncStatus(SyncStatus.created);
    final result1 = await strengthSessionApi.postMultiple(sessionsToCreate);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSessionDb.setAllCreatedSynchronized();

    final setsToCreate =
        await strengthSetDb.getWithSyncStatus(SyncStatus.created);
    final result2 = await strengthSetApi.postMultiple(setsToCreate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    strengthSetDb.setAllCreatedSynchronized();
  }

  @override
  Future<void> updateSingle(StrengthSessionDescription object) async {
    assert(object.isValid());

    final oldSets = await strengthSetDb.getByStrengthSession(object.id);
    final newSets = [...object.strengthSets!];

    final diffing = diff(oldSets, newSets);

    await strengthSessionDb.updateSingle(object.strengthSession);
    await strengthSetDb.deleteMultiple(diffing.toDelete);
    await strengthSetDb.updateMultiple(diffing.toUpdate);
    await strengthSetDb.createMultiple(diffing.toCreate);
    notifyListeners();

    final result1 = await strengthSessionApi.putSingle(object.strengthSession);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSessionDb.setSynchronized(object.id);

    for (final ss in diffing.toDelete) {
      ss.deleted = true;
    }
    final result2 =
        await strengthSetApi.putMultiple(diffing.toDelete + diffing.toUpdate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }

    final result3 = await strengthSetApi.postMultiple(diffing.toCreate);
    if (result3.isFailure) {
      handleApiError(result3.failure);
      return;
    }
    strengthSetDb.setSynchronizedByStrengthSession(object.id);
  }

  // this can be very inefficient and should be avoided when having huge lists of sessions
  Future<void> populateWithSets(
      List<StrengthSessionDescription> sessions) async {
    for (final session in sessions) {
      session.strengthSets =
          await strengthSetDb.getByStrengthSession(session.id);
    }
  }

  Future<List<StrengthSessionDescription>> getSessionsWithStats({
    Int64? movementId,
    DateTime? from,
    DateTime? until,
    String? movementName,
    bool withSets = false,
  }) async {
    assert(movementName == null || movementId == null);
    final sessions = await strengthSessionDb.getSessionDescriptions(
      from: from,
      until: until,
      movementIdValue: movementId,
      movementName: movementName,
    );
    if (withSets) {
      await populateWithSets(sessions);
    }
    return sessions;
  }

  // weekly/monthly view
  Future<List<StrengthSessionStats>> getStatsByDay({
    required Int64 movementId,
    required DateTime from,
    required DateTime until,
  }) async {
    return strengthSessionDb.getStatsAggregationsByDay(
        movementIdValue: movementId, from: from, until: until);
  }

  // yearly view
  Future<List<StrengthSessionStats>> getStatsByWeek({
    required Int64 movementId,
    required DateTime from,
    required DateTime until,
  }) async {
    return strengthSessionDb.getStatsAggregationsByWeek(
        from: from, until: until, movementIdValue: movementId);
  }

  // all time view
  Future<List<StrengthSessionStats>> getStatsByMonth(
      {required Int64 movementId}) async {
    return strengthSessionDb.getStatsAggregationsByMonth(
        movementIdValue: movementId);
  }

  Future<void> upsertMultipleSessions(List<StrengthSession> sessions,
      {required bool synchronized}) async {
    await strengthSessionDb.upsertMultiple(sessions,
        synchronized: synchronized);
    notifyListeners();
  }

  Future<void> upsertMultipleSets(List<StrengthSet> sets,
      {required bool synchronized}) async {
    await strengthSetDb.upsertMultiple(sets, synchronized: synchronized);
    notifyListeners();
  }

  @override
  Future<void> upsertPartOfAccountData(AccountData accountData) async {
    await strengthSessionDb.upsertMultiple(accountData.strengthSessions,
        synchronized: true);
    await strengthSetDb.upsertMultiple(accountData.strengthSets,
        synchronized: true);
    notifyListeners();
  }
}
