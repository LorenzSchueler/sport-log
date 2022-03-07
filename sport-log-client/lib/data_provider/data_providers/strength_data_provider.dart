import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
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

class StrengthSessionDescriptionDataProvider
    extends DataProvider<StrengthSessionDescription> {
  final _strengthSessionDb = AppDatabase.strengthSessions;
  final _strengthSetDb = AppDatabase.strengthSets;
  final _movementDb = AppDatabase.movements;

  final _strengthSessionApi = Api.strengthSessions;
  final _strengthSetApi = Api.strengthSets;

  final _strengthSessionDataProvider = StrengthSessionDataProvider.instance;
  final _strengthSetDataProvider = StrengthSetDataProvider.instance;
  final _movementDataProvider = MovementDataProvider.instance;

  StrengthSessionDescriptionDataProvider._();
  static StrengthSessionDescriptionDataProvider? _instance;
  static StrengthSessionDescriptionDataProvider get instance {
    if (_instance == null) {
      _instance = StrengthSessionDescriptionDataProvider._();
      _instance!._strengthSessionDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._strengthSetDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._movementDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  @override
  Future<bool> createSingle(StrengthSessionDescription object) async {
    assert(object.isValid());
    // TODO: catch errors
    await _strengthSessionDb.createSingle(object.session);
    await _strengthSetDb.createMultiple(object.sets);
    notifyListeners();
    final result1 = await _strengthSessionApi.postSingle(object.session);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    _strengthSessionDb.setSynchronized(object.session.id);
    final result2 = await _strengthSetApi.postMultiple(object.sets);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    _strengthSetDb.setSynchronizedByStrengthSession(object.session.id);
    return true;
  }

  @override
  Future<bool> updateSingle(StrengthSessionDescription object) async {
    assert(object.isValid());

    final oldSets =
        await _strengthSetDb.getByStrengthSession(object.session.id);
    final newSets = [...object.sets];

    final diffing = diff(oldSets, newSets);

    await _strengthSessionDb.updateSingle(object.session);
    await _strengthSetDb.deleteMultiple(diffing.toDelete);
    await _strengthSetDb.updateMultiple(diffing.toUpdate);
    await _strengthSetDb.createMultiple(diffing.toCreate);
    notifyListeners();

    final result1 = await _strengthSessionApi.putSingle(object.session);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    _strengthSessionDb.setSynchronized(object.session.id);

    for (final ss in diffing.toDelete) {
      ss.deleted = true;
    }
    final result2 =
        await _strengthSetApi.putMultiple(diffing.toDelete + diffing.toUpdate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }

    final result3 = await _strengthSetApi.postMultiple(diffing.toCreate);
    if (result3.isFailure) {
      handleApiError(result3.failure);
      return false;
    }
    _strengthSetDb.setSynchronizedByStrengthSession(object.session.id);
    return true;
  }

  @override
  Future<bool> deleteSingle(StrengthSessionDescription object) async {
    object.setDeleted();
    // TODO: catch errors
    await _strengthSetDb.deleteByStrengthSession(object.session.id);
    await _strengthSessionDb.deleteSingle(object.session.id);
    notifyListeners();
    // TODO: server deletes strength sets automatically
    final result1 = await _strengthSetApi.putMultiple(object.sets);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return false;
    }
    _strengthSetDb.setSynchronizedByStrengthSession(object.session.id);
    final result2 = await _strengthSessionApi.putSingle(object.session);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return false;
    }
    _strengthSessionDb.setSynchronized(object.session.id);
    return true;
  }

  @override
  Future<List<StrengthSessionDescription>> getNonDeleted() async {
    return Future.wait(
      (await _strengthSessionDb.getNonDeleted())
          .map(
            (session) async => StrengthSessionDescription(
              session: session,
              movement: (await _movementDb.getSingle(session.movementId))!,
              sets: await _strengthSetDb.getByStrengthSession(session.id),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> pushUpdatedToServer() async {
    final sessionsToUpdate =
        await _strengthSessionDb.getWithSyncStatus(SyncStatus.updated);
    final result1 = await _strengthSessionApi.putMultiple(sessionsToUpdate);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    _strengthSessionDb.setAllUpdatedSynchronized();

    final setsToUpdate =
        await _strengthSetDb.getWithSyncStatus(SyncStatus.updated);
    final result2 = await _strengthSetApi.putMultiple(setsToUpdate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    _strengthSetDb.setAllUpdatedSynchronized();
  }

  @override
  Future<void> pushCreatedToServer() async {
    final sessionsToCreate =
        await _strengthSessionDb.getWithSyncStatus(SyncStatus.created);
    final result1 = await _strengthSessionApi.postMultiple(sessionsToCreate);
    if (result1.isFailure) {
      handleApiError(result1.failure);
      return;
    }
    _strengthSessionDb.setAllCreatedSynchronized();

    final setsToCreate =
        await _strengthSetDb.getWithSyncStatus(SyncStatus.created);
    final result2 = await _strengthSetApi.postMultiple(setsToCreate);
    if (result2.isFailure) {
      handleApiError(result2.failure);
      return;
    }
    _strengthSetDb.setAllCreatedSynchronized();
  }

  @override
  Future<void> pullFromServer() async {
    final result1 = await _strengthSessionApi.getMultiple();
    if (result1.isFailure) {
      handleApiError(result1.failure, internetRequired: true);
      return;
    }
    await _strengthSessionDb.upsertMultiple(
      result1.success,
      synchronized: true,
    );

    final result2 = await _strengthSetApi.getMultiple();
    if (result2.isFailure) {
      notifyListeners();
      handleApiError(result2.failure, internetRequired: true);
      return;
    }
    await _strengthSetDb.upsertMultiple(result2.success, synchronized: true);
    notifyListeners();
  }

  Future<StrengthSessionDescription?> getById(Int64 id) async =>
      _strengthSessionDb.getById(id);

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovement({
    Int64? movementId,
    DateTime? from,
    DateTime? until,
  }) async {
    return _strengthSessionDb.getByTimerangeAndMovement(
      from: from,
      until: until,
      movementIdValue: movementId,
    );
  }

  Future<List<StrengthSet>> getSetsOnDay({
    required DateTime date,
    required Int64 movementId,
  }) async =>
      _strengthSessionDb.getSetsOnDay(date: date, movementIdValue: movementId);

  // weekly/monthly view
  Future<List<StrengthSessionStats>> getStatsAggregationsByDay({
    required Int64 movementId,
    required DateTime from,
    required DateTime until,
  }) async {
    return _strengthSessionDb.getStatsAggregationsByDay(
      movementIdValue: movementId,
      from: from,
      until: until,
    );
  }

  // yearly view
  Future<List<StrengthSessionStats>> getStatsAggregationsByWeek({
    required Int64 movementId,
    required DateTime from,
    required DateTime until,
  }) async {
    return _strengthSessionDb.getStatsAggregationsByWeek(
      from: from,
      until: until,
      movementIdValue: movementId,
    );
  }

  // all time view
  Future<List<StrengthSessionStats>> getStatsAggregationsByMonth({
    required Int64 movementId,
  }) async {
    return _strengthSessionDb.getStatsAggregationsByMonth(
      movementIdValue: movementId,
    );
  }

  Future<void> upsertMultipleSessions(
    List<StrengthSession> sessions, {
    required bool synchronized,
  }) async {
    await _strengthSessionDb.upsertMultiple(
      sessions,
      synchronized: synchronized,
    );
    notifyListeners();
  }

  Future<void> upsertMultipleSets(
    List<StrengthSet> sets, {
    required bool synchronized,
  }) async {
    await _strengthSetDb.upsertMultiple(sets, synchronized: synchronized);
    notifyListeners();
  }
}
