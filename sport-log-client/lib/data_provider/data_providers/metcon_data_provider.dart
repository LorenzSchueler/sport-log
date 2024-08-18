import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/accessors/metcon_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/metcon_tables.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/epoch/epoch_map.dart';
import 'package:sport_log/models/epoch/epoch_result.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';

class MetconDataProvider extends EntityDataProvider<Metcon> {
  factory MetconDataProvider() => _instance;

  MetconDataProvider._();

  static final _instance = MetconDataProvider._();

  @override
  final Api<Metcon> api = MetconApi();

  @override
  final MetconTable table = MetconTable();

  @override
  List<Metcon> getFromAccountData(AccountData accountData) =>
      accountData.metcons;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.metcon = epochResult.epoch;
  }

  Future<List<Metcon>> getByName(String? name) async {
    return (await table.getNonDeleted())
        .fuzzySort(query: name, toString: (m) => m.name);
  }
}

class MetconMovementDataProvider extends EntityDataProvider<MetconMovement> {
  factory MetconMovementDataProvider() => _instance;

  MetconMovementDataProvider._();

  static final _instance = MetconMovementDataProvider._();

  @override
  final Api<MetconMovement> api = MetconMovementApi();

  @override
  final MetconMovementTable table = MetconMovementTable();

  @override
  List<MetconMovement> getFromAccountData(AccountData accountData) =>
      accountData.metconMovements;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.metconMovement = epochResult.epoch;
  }

  Future<List<MetconMovement>> getByMetcon(Metcon metcon) =>
      table.getByMetcon(metcon);
}

class MetconSessionDataProvider extends EntityDataProvider<MetconSession> {
  factory MetconSessionDataProvider() => _instance;

  MetconSessionDataProvider._();

  static final _instance = MetconSessionDataProvider._();

  @override
  final Api<MetconSession> api = MetconSessionApi();

  @override
  final MetconSessionTable table = MetconSessionTable();

  @override
  List<MetconSession> getFromAccountData(AccountData accountData) =>
      accountData.metconSessions;

  @override
  void setEpoch(EpochMap epochMap, EpochResult epochResult) {
    epochMap.metconSession = epochResult.epoch;
  }

  Future<bool> existsByMetcon(Metcon metcon) => table.existsByMetcon(metcon);

  Future<List<MetconSession>> getByTimerangeAndMetconAndComment({
    required DateTime? from,
    required DateTime? until,
    required Metcon? metcon,
    required String? comment,
  }) =>
      table.getByTimerangeAndMetconAndComment(
        from: from,
        until: until,
        metcon: metcon,
        comment: comment,
      );

  Future<MetconRecords> getMetconRecords() => table.getMetconRecords();
}

class MetconDescriptionDataProvider extends DataProvider<MetconDescription> {
  factory MetconDescriptionDataProvider() {
    if (_instance == null) {
      _instance = MetconDescriptionDataProvider._();
      _instance!._metconDataProvider.addListener(_instance!.notifyListeners);
      _instance!._metconMovementDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._movementDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }
  MetconDescriptionDataProvider._();

  static MetconDescriptionDataProvider? _instance;

  final _metconDataProvider = MetconDataProvider();
  final _metconMovementDataProvider = MetconMovementDataProvider();
  final _movementDataProvider = MovementDataProvider();
  final _metconSessionDataProvider =
      MetconSessionDataProvider(); // don't forward notifications

  @override
  Future<DbResult> createSingle(MetconDescription object) async {
    object.sanitize();
    assert(object.isValid());
    final result =
        await _metconDataProvider.createSingle(object.metcon, notify: false);
    if (result.isErr) {
      return result;
    }
    return _metconMovementDataProvider.createMultiple(
      object.moves.map((mmd) => mmd.metconMovement).toList(),
    );
  }

  @override
  Future<DbResult> updateSingle(MetconDescription object) async {
    object.sanitize();
    assert(object.isValid());

    var result =
        await _metconDataProvider.updateSingle(object.metcon, notify: false);
    if (result.isErr) {
      return result;
    }

    // Updating metconMovements does not work because one movement can end up having the same movementNumber (and metconId) and an existing movement.
    // Temporarily setting the movementNumber to a higher value and updating it afterwards also does not work
    // because the same problem will occur on the server side when the changes are synchronized.
    // Since this is not an EntityDataProvider this method is not used for updates coming from the server.
    final oldMMovements =
        await _metconMovementDataProvider.getByMetcon(object.metcon);
    final newMMovements = object.moves
        .map(
          (m) => m.metconMovement..id = randomId(),
        )
        .toList();
    result = await _metconMovementDataProvider.deleteMultiple(
      oldMMovements,
      notify: false,
    );
    if (result.isErr) {
      return result;
    }
    return _metconMovementDataProvider.createMultiple(newMMovements);
  }

  @override
  Future<DbResult> deleteSingle(MetconDescription object) async {
    final result = await _metconMovementDataProvider.deleteMultiple(
      object.moves.map((e) => e.metconMovement).toList(),
      notify: false,
    );
    if (result.isErr) {
      return result;
    }
    return _metconDataProvider.deleteSingle(object.metcon);
  }

  @override
  Future<List<MetconDescription>> getNonDeleted() async {
    return Future.wait(
      (await _metconDataProvider.getNonDeleted()).map(getByMetcon).toList(),
    );
  }

  Future<void> setDefaultMetconDescription() async {
    final metcon = await _metconDataProvider.table.getDefaultMetcon();
    if (metcon == null) {
      return;
    }
    final metconDescription = MetconDescription(
      metcon: metcon,
      moves: await _getMmdByMetcon(metcon),
      hasReference: await _metconSessionDataProvider.existsByMetcon(metcon),
    );
    MetconDescription.defaultMetconDescription = metconDescription;
  }

  Future<List<MetconMovementDescription>> _getMmdByMetcon(Metcon metcon) async {
    final metconMovements =
        await _metconMovementDataProvider.getByMetcon(metcon);
    return Future.wait(
      metconMovements
          .map(
            (mm) async => MetconMovementDescription(
              metconMovement: mm,
              movement: (await _movementDataProvider.getById(mm.movementId))!,
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
      moves: await _getMmdByMetcon(metcon),
      hasReference: await _metconSessionDataProvider.existsByMetcon(metcon),
    );
  }

  Future<MetconDescription> getByMetcon(Metcon metcon) async {
    return MetconDescription(
      metcon: metcon,
      moves: await _getMmdByMetcon(metcon),
      hasReference: await _metconSessionDataProvider.existsByMetcon(metcon),
    );
  }

  Future<List<MetconDescription>> getByMetconName(String? name) async {
    final metcons = await _metconDataProvider.getByName(name);
    return Future.wait(
      metcons.map(
        (metcon) async => MetconDescription(
          metcon: metcon,
          moves: await _getMmdByMetcon(metcon),
          hasReference: await _metconSessionDataProvider.existsByMetcon(metcon),
        ),
      ),
    );
  }
}

class MetconSessionDescriptionDataProvider
    extends DataProvider<MetconSessionDescription> {
  factory MetconSessionDescriptionDataProvider() {
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

  MetconSessionDescriptionDataProvider._();

  final _metconSessionDataProvider = MetconSessionDataProvider();
  final _metconDataProvider = MetconDataProvider();
  final _metconMovementDataProvider = MetconMovementDataProvider();
  final _movementDataProvider = MovementDataProvider();
  final _metconDescriptionDataProvider =
      MetconDescriptionDataProvider(); // don't forward notifications

  static MetconSessionDescriptionDataProvider? _instance;

  @override
  Future<DbResult> createSingle(MetconSessionDescription object) async {
    return _metconSessionDataProvider.createSingle(object.metconSession);
  }

  @override
  Future<DbResult> updateSingle(MetconSessionDescription object) async {
    return _metconSessionDataProvider.updateSingle(object.metconSession);
  }

  @override
  Future<DbResult> deleteSingle(MetconSessionDescription object) async {
    return _metconSessionDataProvider.deleteSingle(object.metconSession);
  }

  @override
  Future<List<MetconSessionDescription>> getNonDeleted() async {
    return _mapToDescription(
      await _metconSessionDataProvider.getNonDeleted(),
    );
  }

  Future<List<MetconSessionDescription>> getByTimerangeAndMetconAndComment({
    required DateTime? from,
    required DateTime? until,
    required Metcon? metcon,
    required String? comment,
  }) async {
    return _mapToDescription(
      await _metconSessionDataProvider.getByTimerangeAndMetconAndComment(
        from: from,
        until: until,
        metcon: metcon,
        comment: comment,
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

  Future<MetconRecords> getMetconRecords() =>
      _metconSessionDataProvider.getMetconRecords();
}
