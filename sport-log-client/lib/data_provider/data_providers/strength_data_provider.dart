import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionDataProvider extends EntityDataProvider<StrengthSession> {
  static final instance = StrengthSessionDataProvider._();
  StrengthSessionDataProvider._();

  @override
  final Api<StrengthSession> api = Api.strengthSessions;

  @override
  final TableAccessor<StrengthSession> db = AppDatabase.strengthSessions;

  @override
  List<StrengthSession> getFromAccountData(AccountData accountData) =>
      accountData.strengthSessions;
}

class StrengthSetDataProvider extends EntityDataProvider<StrengthSet> {
  static final instance = StrengthSetDataProvider._();
  StrengthSetDataProvider._();

  @override
  final Api<StrengthSet> api = Api.strengthSets;

  @override
  final TableAccessor<StrengthSet> db = AppDatabase.strengthSets;

  @override
  List<StrengthSet> getFromAccountData(AccountData accountData) =>
      accountData.strengthSets;
}

class StrengthSessionWithSetsDataProvider
    extends DataProvider<StrengthSessionWithSets> {
  final strengthSessionDb = AppDatabase.strengthSessions;
  final strengthSetDb = AppDatabase.strengthSets;
  final movementDb = AppDatabase.movements;

  final strengthSessionApi = Api.strengthSessions;
  final strengthSetApi = Api.strengthSets;

  static final instance = StrengthSessionWithSetsDataProvider._();
  StrengthSessionWithSetsDataProvider._();

  @override
  Future<void> createSingle(StrengthSessionWithSets object) async {
    assert(object.isValid());
    // TODO: catch errors
    await strengthSessionDb.createSingle(object.session);
    await strengthSetDb.createMultiple(object.sets);
    notifyListeners();
    final result1 = await strengthSessionApi.postSingle(object.session);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSessionDb.setSynchronized(object.id);
    final result2 = await strengthSetApi.postMultiple(object.sets);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    strengthSetDb.setSynchronizedByStrengthSession(object.id);
  }

  @override
  Future<void> deleteSingle(StrengthSessionWithSets object) async {
    object.setDeleted();
    // TODO: catch errors
    await strengthSetDb.deleteByStrengthSession(object.id);
    await strengthSessionDb.deleteSingle(object.id);
    notifyListeners();
    // TODO: server deletes strength sets automatically
    final result1 = await strengthSetApi.putMultiple(object.sets);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    strengthSetDb.setSynchronizedByStrengthSession(object.id);
    final result2 = await strengthSessionApi.putSingle(object.session);
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
      handleApiError(result1.failure, isCritical: true);
      return;
    }
    await strengthSessionDb.upsertMultiple(result1.success, synchronized: true);

    final result2 = await strengthSetApi.getMultiple();
    if (result2.isFailure) {
      notifyListeners();
      handleApiError(result2.failure, isCritical: true);
      return;
    }
    strengthSetDb
        .upsertMultiple(result2.success, synchronized: true)
        .then((_) => notifyListeners());
  }

  @override
  Future<List<StrengthSessionWithSets>> getNonDeleted() async {
    throw UnimplementedError();
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
  Future<void> updateSingle(StrengthSessionWithSets object) async {
    assert(object.isValid());

    final oldSets = await strengthSetDb.getByStrengthSession(object.id);
    final newSets = [...object.sets];

    final diffing = diff(oldSets, newSets);

    await strengthSessionDb.updateSingle(object.session);
    await strengthSetDb.deleteMultiple(diffing.toDelete);
    await strengthSetDb.updateMultiple(diffing.toUpdate);
    await strengthSetDb.createMultiple(diffing.toCreate);
    notifyListeners();

    final result1 = await strengthSessionApi.putSingle(object.session);
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

  Future<StrengthSessionWithSets?> getSessionWithSets(Int64 id) async =>
      strengthSessionDb.getSessionWithSets(id);

  Future<List<StrengthSessionWithStats>> getSessionsWithStats({
    Int64? movementId,
    DateTime? from,
    DateTime? until,
  }) async {
    return strengthSessionDb.getSessionsWithStats(
        from: from, until: until, movementIdValue: movementId);
  }

  Future<List<StrengthSet>> getSetsOnDay({
    required DateTime date,
    required Int64 movementId,
  }) async =>
      strengthSessionDb.getSetsOnDay(date: date, movementIdValue: movementId);

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
  Future<void> upsertFromAccountData(AccountData accountData) async {
    await strengthSessionDb.upsertMultiple(accountData.strengthSessions,
        synchronized: true);
    await strengthSetDb.upsertMultiple(accountData.strengthSets,
        synchronized: true);
    notifyListeners();
  }
}
