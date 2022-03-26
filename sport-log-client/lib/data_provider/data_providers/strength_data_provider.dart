import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/strength_tables.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionDataProvider extends EntityDataProvider<StrengthSession> {
  static final _instance = StrengthSessionDataProvider._();
  StrengthSessionDataProvider._();
  factory StrengthSessionDataProvider() => _instance;

  @override
  final Api<StrengthSession> api = Api.strengthSessions;

  @override
  final TableAccessor<StrengthSession> db = AppDatabase.strengthSessions;

  @override
  List<StrengthSession> getFromAccountData(AccountData accountData) =>
      accountData.strengthSessions;
}

class StrengthSetDataProvider extends EntityDataProvider<StrengthSet> {
  static final _instance = StrengthSetDataProvider._();
  StrengthSetDataProvider._();
  factory StrengthSetDataProvider() => _instance;

  @override
  final Api<StrengthSet> api = Api.strengthSets;

  @override
  final StrengthSetTable db = AppDatabase.strengthSets;

  @override
  List<StrengthSet> getFromAccountData(AccountData accountData) =>
      accountData.strengthSets;

  Future<List<StrengthSet>> getByStrengthSession(Int64 strengthSessionId) =>
      db.getByStrengthSession(strengthSessionId);

  Future<void> deleteByStrengthSession(Int64 strengthSessionId) =>
      db.deleteByStrengthSession(strengthSessionId);
}

class StrengthSessionDescriptionDataProvider
    extends DataProvider<StrengthSessionDescription> {
  final _strengthSessionDescriptionDb = AppDatabase.strengthSessionDescriptions;

  final _strengthSessionDataProvider = StrengthSessionDataProvider();
  final _strengthSetDataProvider = StrengthSetDataProvider();
  final _movementDataProvider = MovementDataProvider();

  StrengthSessionDescriptionDataProvider._();
  static StrengthSessionDescriptionDataProvider? _instance;
  factory StrengthSessionDescriptionDataProvider() {
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
  Future<DbResult> createSingle(StrengthSessionDescription object) async {
    object.sanitize();
    assert(object.isValid());
    final result =
        await _strengthSessionDataProvider.createSingle(object.session);
    if (result.isFailure()) {
      return result;
    }
    return await _strengthSetDataProvider.createMultiple(object.sets);
  }

  @override
  Future<DbResult> updateSingle(StrengthSessionDescription object) async {
    object.sanitize();
    assert(object.isValid());

    final oldSets =
        await _strengthSetDataProvider.getByStrengthSession(object.session.id);
    final newSets = [...object.sets];
    final diffing = diff(oldSets, newSets);

    var result =
        await _strengthSessionDataProvider.updateSingle(object.session);
    if (result.isFailure()) {
      return result;
    }
    result = await _strengthSetDataProvider.deleteMultiple(diffing.toDelete);
    if (result.isFailure()) {
      return result;
    }
    result = await _strengthSetDataProvider.updateMultiple(diffing.toUpdate);
    if (result.isFailure()) {
      return result;
    }
    return await _strengthSetDataProvider.createMultiple(diffing.toCreate);
  }

  @override
  Future<DbResult> deleteSingle(StrengthSessionDescription object) async {
    object.setDeleted();
    await _strengthSetDataProvider.deleteByStrengthSession(object.session.id);
    return await _strengthSessionDataProvider.deleteSingle(object.session);
  }

  @override
  Future<List<StrengthSessionDescription>> getNonDeleted() async {
    return Future.wait(
      (await _strengthSessionDataProvider.getNonDeleted())
          .map(
            (session) async => StrengthSessionDescription(
              session: session,
              movement:
                  (await _movementDataProvider.getById(session.movementId))!,
              sets: await _strengthSetDataProvider
                  .getByStrengthSession(session.id),
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

  Future<StrengthSessionDescription?> getById(Int64 id) =>
      _strengthSessionDescriptionDb.getById(id);

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovement({
    Int64? movementId,
    DateTime? from,
    DateTime? until,
  }) async {
    return _strengthSessionDescriptionDb.getByTimerangeAndMovement(
      from: from,
      until: until,
      movementIdValue: movementId,
    );
  }

  Future<List<StrengthSet>> getSetsOnDay({
    required DateTime date,
    required Int64 movementId,
  }) async =>
      _strengthSessionDescriptionDb.getSetsOnDay(
        date: date,
        movementIdValue: movementId,
      );

  // weekly/monthly view
  Future<List<StrengthSessionStats>> getStatsAggregationsByDay({
    required Int64 movementId,
    required DateTime from,
    required DateTime until,
  }) async {
    return _strengthSessionDescriptionDb.getStatsAggregationsByDay(
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
    return _strengthSessionDescriptionDb.getStatsAggregationsByWeek(
      from: from,
      until: until,
      movementIdValue: movementId,
    );
  }

  // all time view
  Future<List<StrengthSessionStats>> getStatsAggregationsByMonth({
    required Int64 movementId,
  }) async {
    return _strengthSessionDescriptionDb.getStatsAggregationsByMonth(
      movementIdValue: movementId,
    );
  }

  Future<void> upsertMultipleSessions(
    List<StrengthSession> sessions, {
    required bool synchronized,
  }) async {
    await _strengthSessionDataProvider.upsertMultiple(
      sessions,
      synchronized: synchronized,
    );
    notifyListeners();
  }

  Future<void> upsertMultipleSets(
    List<StrengthSet> sets, {
    required bool synchronized,
  }) async {
    await _strengthSetDataProvider.upsertMultiple(
      sets,
      synchronized: synchronized,
    );
    notifyListeners();
  }
}
