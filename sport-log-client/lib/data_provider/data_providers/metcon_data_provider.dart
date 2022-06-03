import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/metcon_tables.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/models/all.dart';

class MetconDataProvider extends EntityDataProvider<Metcon> {
  factory MetconDataProvider() => _instance;

  MetconDataProvider._();

  static final _instance = MetconDataProvider._();

  @override
  final Api<Metcon> api = Api.metcons;

  @override
  final MetconTable db = AppDatabase.metcons;

  @override
  List<Metcon> getFromAccountData(AccountData accountData) =>
      accountData.metcons;

  Future<List<Metcon>> getByName(String? name) async {
    return (await db.getNonDeleted())
        .fuzzySortByKey(key: name, toString: (m) => m.name);
  }
}

class MetconMovementDataProvider extends EntityDataProvider<MetconMovement> {
  factory MetconMovementDataProvider() => _instance;

  MetconMovementDataProvider._();

  static final _instance = MetconMovementDataProvider._();

  @override
  final Api<MetconMovement> api = Api.metconMovements;

  @override
  final MetconMovementTable db = AppDatabase.metconMovements;

  @override
  List<MetconMovement> getFromAccountData(AccountData accountData) =>
      accountData.metconMovements;

  Future<List<MetconMovement>> getByMetcon(Metcon metcon) =>
      db.getByMetcon(metcon);
}

class MetconSessionDataProvider extends EntityDataProvider<MetconSession> {
  factory MetconSessionDataProvider() => _instance;

  MetconSessionDataProvider._();

  static final _instance = MetconSessionDataProvider._();

  @override
  final Api<MetconSession> api = Api.metconSessions;

  @override
  final MetconSessionTable db = AppDatabase.metconSessions;

  @override
  List<MetconSession> getFromAccountData(AccountData accountData) =>
      accountData.metconSessions;

  Future<bool> existsByMetcon(Metcon metcon) => db.existsByMetcon(metcon);

  Future<List<MetconSession>> getByTimerangeAndMetcon({
    Metcon? metcon,
    DateTime? from,
    DateTime? until,
  }) =>
      db.getByTimerangeAndMetcon(
        metconValue: metcon,
        from: from,
        until: until,
      );
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
    var result =
        await _metconDataProvider.createSingle(object.metcon, notify: false);
    if (result.isFailure()) {
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

    final oldMMovements =
        await _metconMovementDataProvider.getByMetcon(object.metcon);
    final newMMovements = [...object.moves.map((m) => m.metconMovement)];

    final diffing = diff(oldMMovements, newMMovements);

    var result =
        await _metconDataProvider.updateSingle(object.metcon, notify: false);
    if (result.isFailure()) {
      return result;
    }
    result = await _metconMovementDataProvider.deleteMultiple(
      diffing.toDelete,
      notify: false,
    );
    if (result.isFailure()) {
      return result;
    }
    result = await _metconMovementDataProvider.updateMultiple(
      diffing.toUpdate,
      notify: false,
    );
    if (result.isFailure()) {
      return result;
    }
    return _metconMovementDataProvider.createMultiple(diffing.toCreate);
  }

  @override
  Future<DbResult> deleteSingle(MetconDescription object) async {
    final result = await _metconMovementDataProvider.deleteMultiple(
      object.moves.map((e) => e.metconMovement).toList(),
      notify: false,
    );
    if (result.isFailure()) {
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

  @override
  Future<bool> pushUpdatedToServer() async {
    if (await _metconDataProvider.pushUpdatedToServer()) {
      return false;
    }
    return _metconMovementDataProvider.pushUpdatedToServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    if (await _metconDataProvider.pushCreatedToServer()) {
      return false;
    }
    return _metconMovementDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pullFromServer() async {
    if (await _metconDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    return _metconMovementDataProvider.pullFromServer();
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

  @override
  Future<bool> pullFromServer() async {
    if (!await _movementDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    if (!await _metconDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    if (!await _metconMovementDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    return _metconSessionDataProvider.pullFromServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return _metconSessionDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return _metconSessionDataProvider.pushUpdatedToServer();
  }

  Future<List<MetconSessionDescription>> getByTimerangeAndMetcon({
    Metcon? metcon,
    DateTime? from,
    DateTime? until,
  }) async {
    return _mapToDescription(
      await _metconSessionDataProvider.getByTimerangeAndMetcon(
        from: from,
        until: until,
        metcon: metcon,
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
