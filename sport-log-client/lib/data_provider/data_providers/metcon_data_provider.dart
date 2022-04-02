import 'package:fixnum/fixnum.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/tables/metcon_tables.dart';
import 'package:sport_log/helpers/diff_algorithm.dart';
import 'package:sport_log/models/all.dart';

class MetconDataProvider extends EntityDataProvider<Metcon> {
  static final _instance = MetconDataProvider._();
  MetconDataProvider._();
  factory MetconDataProvider() => _instance;

  @override
  final Api<Metcon> api = Api.metcons;

  @override
  final MetconTable db = AppDatabase.metcons;

  @override
  List<Metcon> getFromAccountData(AccountData accountData) =>
      accountData.metcons;

  Future<List<Metcon>> getByName(String? name) => db.getByName(name);
}

class MetconMovementDataProvider extends EntityDataProvider<MetconMovement> {
  static final _instance = MetconMovementDataProvider._();
  MetconMovementDataProvider._();
  factory MetconMovementDataProvider() => _instance;

  @override
  final Api<MetconMovement> api = Api.metconMovements;

  @override
  final MetconMovementTable db = AppDatabase.metconMovements;

  @override
  List<MetconMovement> getFromAccountData(AccountData accountData) =>
      accountData.metconMovements;

  Future<List<MetconMovement>> getByMetcon(Int64 metconId) =>
      db.getByMetcon(metconId);
}

class MetconSessionDataProvider extends EntityDataProvider<MetconSession> {
  static final _instance = MetconSessionDataProvider._();
  MetconSessionDataProvider._();
  factory MetconSessionDataProvider() => _instance;

  @override
  final Api<MetconSession> api = Api.metconSessions;

  @override
  final MetconSessionTable db = AppDatabase.metconSessions;

  @override
  List<MetconSession> getFromAccountData(AccountData accountData) =>
      accountData.metconSessions;

  Future<bool> existsByMetcon(Int64 metconId) => db.existsByMetcon(metconId);

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
  final _metconDataProvider = MetconDataProvider();
  final _metconMovementDataProvider = MetconMovementDataProvider();
  final _movementDataProvider = MovementDataProvider();
  final _metconSessionDataProvider =
      MetconSessionDataProvider(); // don't forward notifications

  static MetconDescriptionDataProvider? _instance;
  MetconDescriptionDataProvider._();
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

  @override
  Future<DbResult> createSingle(MetconDescription object) async {
    object.sanitize();
    assert(object.isValid());
    var result = await _metconDataProvider.createSingle(object.metcon);
    if (result.isFailure()) {
      return result;
    }
    return await _metconMovementDataProvider.createMultiple(
      object.moves.map((mmd) => mmd.metconMovement).toList(),
    );
  }

  @override
  Future<DbResult> updateSingle(MetconDescription object) async {
    object.sanitize();
    assert(object.isValid());

    final oldMMovements =
        await _metconMovementDataProvider.getByMetcon(object.metcon.id);
    final newMMovements = [...object.moves.map((m) => m.metconMovement)];

    final diffing = diff(oldMMovements, newMMovements);

    var result = await _metconDataProvider.updateSingle(object.metcon);
    if (result.isFailure()) {
      return result;
    }
    result = await _metconMovementDataProvider.deleteMultiple(diffing.toDelete);
    if (result.isFailure()) {
      return result;
    }
    result = await _metconMovementDataProvider.updateMultiple(diffing.toUpdate);
    if (result.isFailure()) {
      return result;
    }
    return await _metconMovementDataProvider.createMultiple(diffing.toCreate);
  }

  @override
  Future<DbResult> deleteSingle(MetconDescription object) async {
    final result = await _metconMovementDataProvider
        .deleteMultiple(object.moves.map((e) => e.metconMovement).toList());
    if (result.isFailure()) {
      return result;
    }
    return await _metconDataProvider.deleteSingle(object.metcon);
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
    return await _metconMovementDataProvider.pushUpdatedToServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    if (await _metconDataProvider.pushCreatedToServer()) {
      return false;
    }
    return await _metconMovementDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pullFromServer() async {
    if (await _metconDataProvider.pullFromServer()) {
      return false;
    }
    return await _metconMovementDataProvider.pullFromServer();
  }

  Future<List<MetconMovementDescription>> _getMmdByMetcon(Int64 id) async {
    final metconMovements = await _metconMovementDataProvider.getByMetcon(id);
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
      moves: await _getMmdByMetcon(metcon.id),
      hasReference: await _metconSessionDataProvider.existsByMetcon(metcon.id),
    );
  }

  Future<MetconDescription> getByMetcon(Metcon metcon) async {
    return MetconDescription(
      metcon: metcon,
      moves: await _getMmdByMetcon(metcon.id),
      hasReference: await _metconSessionDataProvider.existsByMetcon(metcon.id),
    );
  }
}

class MetconSessionDescriptionDataProvider
    extends DataProvider<MetconSessionDescription> {
  final _metconSessionDataProvider = MetconSessionDataProvider();
  final _metconDataProvider = MetconDataProvider();
  final _metconMovementDataProvider = MetconMovementDataProvider();
  final _movementDataProvider = MovementDataProvider();
  final _metconDescriptionDataProvider =
      MetconDescriptionDataProvider(); // don't forward notifications

  static MetconSessionDescriptionDataProvider? _instance;
  MetconSessionDescriptionDataProvider._();
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

  @override
  Future<DbResult> createSingle(MetconSessionDescription object) async {
    return await _metconSessionDataProvider.createSingle(object.metconSession);
  }

  @override
  Future<DbResult> updateSingle(MetconSessionDescription object) async {
    return await _metconSessionDataProvider.updateSingle(object.metconSession);
  }

  @override
  Future<DbResult> deleteSingle(MetconSessionDescription object) async {
    return await _metconSessionDataProvider.deleteSingle(object.metconSession);
  }

  @override
  Future<List<MetconSessionDescription>> getNonDeleted() async {
    return await _mapToDescription(
      await _metconSessionDataProvider.getNonDeleted(),
    );
  }

  @override
  Future<bool> pullFromServer() async {
    if (!await _movementDataProvider.pullFromServer()) {
      return false;
    }
    if (!await _metconDataProvider.pullFromServer()) {
      return false;
    }
    if (!await _metconMovementDataProvider.pullFromServer()) {
      return false;
    }
    return await _metconSessionDataProvider.pullFromServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return await _metconSessionDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return await _metconSessionDataProvider.pushUpdatedToServer();
  }

  Future<List<MetconSessionDescription>> getByTimerangeAndMetcon({
    Metcon? metcon,
    DateTime? from,
    DateTime? until,
  }) async {
    return await _mapToDescription(
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
