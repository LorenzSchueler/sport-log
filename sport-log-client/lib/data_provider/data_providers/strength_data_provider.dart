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
    if (!await _strengthSessionDb.createSingle(object.session)) {
      return false;
    }
    return await _strengthSetDb.createMultiple(object.sets);
  }

  @override
  Future<bool> updateSingle(StrengthSessionDescription object) async {
    assert(object.isValid());
    final oldSets =
        await _strengthSetDb.getByStrengthSession(object.session.id);
    final newSets = [...object.sets];
    final diffing = diff(oldSets, newSets);

    if (!await _strengthSessionDb.updateSingle(object.session)) {
      return false;
    }
    if (!await _strengthSetDb.deleteMultiple(diffing.toDelete)) {
      return false;
    }
    if (!await _strengthSetDb.updateMultiple(diffing.toUpdate)) {
      return false;
    }
    return await _strengthSetDb.createMultiple(diffing.toCreate);
  }

  @override
  Future<bool> deleteSingle(StrengthSessionDescription object) async {
    object.setDeleted();
    await _strengthSetDb.deleteByStrengthSession(object.session.id);
    return await _strengthSessionDb.deleteSingle(object.session.id);
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
  Future<bool> pushUpdatedToServer() async {
    if (!await _strengthSessionDataProvider.pushUpdatedToServer()) {
      return false;
    }
    return await _strengthSetDataProvider.pushUpdatedToServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    if (!await _strengthSessionDataProvider.pushCreatedToServer()) {
      return false;
    }
    return await _strengthSetDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pullFromServer() async {
    if (!await _strengthSessionDataProvider.pullFromServer()) {
      return false;
    }
    return await _strengthSetDataProvider.pullFromServer();
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
