import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/strength_tables.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/models/strength/strength_records.dart';

class StrengthSessionDataProvider extends EntityDataProvider<StrengthSession> {
  factory StrengthSessionDataProvider() => _instance;

  StrengthSessionDataProvider._();

  static final _instance = StrengthSessionDataProvider._();

  @override
  final Api<StrengthSession> api = Api.strengthSessions;

  @override
  final TableAccessor<StrengthSession> db = AppDatabase.strengthSessions;

  @override
  List<StrengthSession> getFromAccountData(AccountData accountData) =>
      accountData.strengthSessions;
}

class StrengthSetDataProvider extends EntityDataProvider<StrengthSet> {
  factory StrengthSetDataProvider() => _instance;

  StrengthSetDataProvider._();

  static final _instance = StrengthSetDataProvider._();

  @override
  final Api<StrengthSet> api = Api.strengthSets;

  @override
  final StrengthSetTable db = AppDatabase.strengthSets;

  @override
  List<StrengthSet> getFromAccountData(AccountData accountData) =>
      accountData.strengthSets;

  Future<List<StrengthSet>> getByStrengthSession(
    StrengthSession strengthSession,
  ) =>
      db.getByStrengthSession(strengthSession);

  Future<StrengthRecords> getStrengthRecords() => db.getStrengthRecords();
}

class StrengthSessionDescriptionDataProvider
    extends DataProvider<StrengthSessionDescription> {
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

  StrengthSessionDescriptionDataProvider._();

  static StrengthSessionDescriptionDataProvider? _instance;

  final _strengthSessionDescriptionDb = AppDatabase.strengthSessionDescriptions;

  final _strengthSessionDataProvider = StrengthSessionDataProvider();
  final _strengthSetDataProvider = StrengthSetDataProvider();
  final _movementDataProvider = MovementDataProvider();

  @override
  Future<DbResult> createSingle(StrengthSessionDescription object) async {
    object.sanitize();
    assert(object.isValid());
    final result = await _strengthSessionDataProvider
        .createSingle(object.session, notify: false);
    if (result.isFailure()) {
      return result;
    }
    return _strengthSetDataProvider.createMultiple(object.sets);
  }

  @override
  Future<DbResult> updateSingle(StrengthSessionDescription object) async {
    object.sanitize();
    assert(object.isValid());

    final oldSets =
        await _strengthSetDataProvider.getByStrengthSession(object.session);
    final newSets = [...object.sets];
    final diffing = diff(oldSets, newSets);

    var result = await _strengthSessionDataProvider.updateSingle(
      object.session,
      notify: false,
    );
    if (result.isFailure()) {
      return result;
    }
    result = await _strengthSetDataProvider.deleteMultiple(
      diffing.toDelete,
      notify: false,
    );
    if (result.isFailure()) {
      return result;
    }
    result = await _strengthSetDataProvider.updateMultiple(
      diffing.toUpdate,
      notify: false,
    );
    if (result.isFailure()) {
      return result;
    }
    return _strengthSetDataProvider.createMultiple(diffing.toCreate);
  }

  @override
  Future<DbResult> deleteSingle(StrengthSessionDescription object) async {
    final result = await _strengthSetDataProvider.deleteMultiple(
      object.sets,
      notify: false,
    );
    if (result.isFailure()) {
      return result;
    }
    return _strengthSessionDataProvider.deleteSingle(object.session);
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
              sets:
                  await _strengthSetDataProvider.getByStrengthSession(session),
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
    return _strengthSetDataProvider.pushUpdatedToServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    if (!await _strengthSessionDataProvider.pushCreatedToServer()) {
      return false;
    }
    return _strengthSetDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pullFromServer() async {
    if (!await _strengthSessionDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    return _strengthSetDataProvider.pullFromServer();
  }

  Future<StrengthSessionDescription?> getById(Int64 id) =>
      _strengthSessionDescriptionDb.getById(id);

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovement({
    Movement? movement,
    DateTime? from,
    DateTime? until,
  }) async {
    return _strengthSessionDescriptionDb.getByTimerangeAndMovement(
      from: from,
      until: until,
      movementValue: movement,
    );
  }

  //// dayly view
  //Future<List<StrengthSessionStats>> getStatsAggregationsBySet({
  //required DateTime date,
  //required Int64 movementId,
  //}) async =>
  //_strengthSessionDescriptionDb.getStatsAggregationsBySet(
  //date: date,
  //movementIdValue: movementId,
  //);

  //// weekly/monthly view
  //Future<List<StrengthSessionStats>> getStatsAggregationsByDay({
  //required Int64 movementId,
  //required DateTime from,
  //required DateTime until,
  //}) async {
  //return _strengthSessionDescriptionDb.getStatsAggregationsByDay(
  //movementIdValue: movementId,
  //from: from,
  //until: until,
  //);
  //}

  //// yearly view
  //Future<List<StrengthSessionStats>> getStatsAggregationsByWeek({
  //required Int64 movementId,
  //required DateTime from,
  //required DateTime until,
  //}) async {
  //return _strengthSessionDescriptionDb.getStatsAggregationsByWeek(
  //from: from,
  //until: until,
  //movementIdValue: movementId,
  //);
  //}

  //// all time view
  //Future<List<StrengthSessionStats>> getStatsAggregationsByMonth({
  //required Int64 movementId,
  //}) async {
  //return _strengthSessionDescriptionDb.getStatsAggregationsByMonth(
  //movementIdValue: movementId,
  //);
  //}

  Future<void> upsertMultipleSessions(
    List<StrengthSession> sessions, {
    required bool synchronized,
  }) async {
    await _strengthSessionDataProvider.upsertMultiple(
      sessions,
      synchronized: synchronized,
    );
  }

  Future<void> upsertMultipleSets(
    List<StrengthSet> sets, {
    required bool synchronized,
  }) async {
    await _strengthSetDataProvider.upsertMultiple(
      sets,
      synchronized: synchronized,
    );
  }

  Future<StrengthRecords> getStrengthRecords() =>
      _strengthSetDataProvider.getStrengthRecords();
}
