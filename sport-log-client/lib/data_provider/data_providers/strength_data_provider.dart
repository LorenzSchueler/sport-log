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
    if (result.isFailure) {
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
    if (result.isFailure) {
      return result;
    }
    result = await _strengthSetDataProvider.deleteMultiple(
      diffing.toDelete,
      notify: false,
    );
    if (result.isFailure) {
      return result;
    }
    result = await _strengthSetDataProvider.updateMultiple(
      diffing.toUpdate,
      notify: false,
    );
    if (result.isFailure) {
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
    if (result.isFailure) {
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

  Future<StrengthSessionDescription?> getById(Int64 id) =>
      _strengthSessionDescriptionDb.getById(id);

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovementAndComment({
    required DateTime? from,
    required DateTime? until,
    required Movement? movement,
    required String? comment,
  }) async {
    return _strengthSessionDescriptionDb.getByTimerangeAndMovementAndComment(
      from: from,
      until: until,
      movement: movement,
      comment: comment,
    );
  }

  Future<StrengthRecords> getStrengthRecords() =>
      _strengthSetDataProvider.getStrengthRecords();
}
