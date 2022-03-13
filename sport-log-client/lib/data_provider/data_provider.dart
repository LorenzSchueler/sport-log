import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/widgets/dialogs/conflict_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/dialogs/new_credentials_dialog.dart';

final _logger = Logger('DataProvider');

abstract class DataProvider<T> extends ChangeNotifier {
  Future<bool> createSingle(T object);

  Future<bool> updateSingle(T object);

  Future<bool> deleteSingle(T object);

  Future<List<T>> getNonDeleted();

  Future<bool> pushUpdatedToServer();

  Future<bool> pushCreatedToServer();

  Future<bool> pullFromServer(); // used in page refresh

  Future<bool> pushToServer() async {
    return (await Future.wait([
      pushUpdatedToServer(),
      pushCreatedToServer(),
    ]))
        .every((result) => result == true);
  }

  /// only called if internet connection is needed
  VoidCallback? _onNoInternet;

  set onNoInternetConnection(VoidCallback? callback) {
    _onNoInternet = callback;
  }

  static Future<ConflictResolution?> handleApiError(
    ApiError error, {
    VoidCallback? onNoInternet,
  }) async {
    _logger.e('Api error: $error', error.errorCode);
    switch (error.errorCode) {
      case ApiErrorCode.serverUnreachable:
        _logger.i("on no internet: $onNoInternet");
        onNoInternet?.call();
        return null;
      case ApiErrorCode.unauthorized:
        _logger.w('Tried sync but access unauthorized.', error);
        await showNewCredentialsDialog();
        return null;
      // create something that refereces non existing object
      case ApiErrorCode.forbidden:
      // primary foreign or unique key violation
      case ApiErrorCode.conflict:
        final conflicResolution = await showConflictDialog(
          context: AppState.globalContext,
          title: "An error occured.",
          text: error.toString(),
        );
        _logger.i(conflicResolution);
        return conflicResolution;
      default:
        await showMessageDialog(
          context: AppState.globalContext,
          title: "An error occured.",
          text: error.toString(),
        );
        return null;
    }
  }
}

abstract class EntityDataProvider<T extends AtomicEntity>
    extends DataProvider<T> {
  Api<T> get api;

  TableAccessor<T> get db;

  List<T> getFromAccountData(AccountData accountData);

  @override
  Future<bool> createSingle(T object) async {
    assert(object.isValid());
    if (!await db.createSingle(object)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateSingle(T object) async {
    assert(object.isValid());
    if (!await db.updateSingle(object)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  @override
  Future<bool> deleteSingle(T object) async {
    if (!await db.deleteSingle(object.id)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> createMultiple(List<T> objects) async {
    assert(objects.every((element) => element.isValid()));
    if (!await db.createMultiple(objects)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> updateMultiple(List<T> objects) async {
    assert(objects.every((element) => element.isValid()));
    if (!await db.updateMultiple(objects)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteMultiple(List<T> objects) async {
    if (!await db.deleteMultiple(objects)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  @override
  Future<List<T>> getNonDeleted() async => db.getNonDeleted();

  @override
  Future<bool> pullFromServer() async {
    final result = await api.getMultiple();
    if (result.isFailure) {
      await DataProvider.handleApiError(
        result.failure,
        onNoInternet: _onNoInternet,
      );
      return false;
    } else {
      return await upsertMultiple(result.success, synchronized: true);
    }
  }

  Future<void> _resolveConflict(
      ConflictResolution conflictResolution, List<T> records) async {
    switch (conflictResolution) {
      case ConflictResolution.automatic:
        _logger.w("solving conflict automatically");
        for (final record in records) {
          // check if this record causes a conflict
          final result = await api.putSingle(record);
          // if record causes conflict delete it
          if (result.isFailure) {
            _logger.w("hard deleting record $record");
            db.hardDeleteSingle(record.id);
          }
        }
        break;
      case ConflictResolution.manual:
        _logger.w("solving conflict manually");
        break;
    }
  }

  Future<bool> _pushEntriesToServer(List<T> records) async {
    final result = await api.putMultiple(records);
    if (result.isFailure) {
      final conflictResolution =
          await DataProvider.handleApiError(result.failure);
      if (conflictResolution != null) {
        await _resolveConflict(conflictResolution, records);
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    final recordsToUpdate = await db.getWithSyncStatus(SyncStatus.updated);
    if (await _pushEntriesToServer(recordsToUpdate)) {
      db.setAllUpdatedSynchronized();
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> pushCreatedToServer() async {
    final recordsToCreate = await db.getWithSyncStatus(SyncStatus.created);
    if (await _pushEntriesToServer(recordsToCreate)) {
      db.setAllCreatedSynchronized();
      return true;
    } else {
      return false;
    }
  }

  Future<T?> getById(Int64 id) async => db.getById(id);

  Future<bool> upsertFromAccountData(AccountData accountData) async {
    return await upsertMultiple(
      getFromAccountData(accountData),
      synchronized: true,
    );
  }

  Future<bool> upsertMultiple(
    List<T> objects, {
    required bool synchronized,
  }) async {
    if (objects.isEmpty) {
      return true;
    }
    if (!await db.upsertMultiple(objects, synchronized: synchronized)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  static Future<void> pushAllToServer() async {
    // !!! order matters => no parallel execution possible
    for (final dp in EntityDataProvider.all) {
      await dp.pushToServer();
    }
  }

  static Future<void> upsertAccountData(
    AccountData data, {
    required bool synchronized,
  }) async {
    // !!! order matters => no parallel execution possible
    for (final dp in EntityDataProvider.all) {
      await dp.upsertFromAccountData(data);
    }
  }

  static List<EntityDataProvider> get all => [
        DiaryDataProvider.instance,
        WodDataProvider.instance,
        MovementDataProvider.instance,
        MetconDataProvider.instance,
        MetconMovementDataProvider.instance,
        MetconSessionDataProvider.instance,
        RouteDataProvider.instance,
        CardioSessionDataProvider.instance,
        StrengthSessionDataProvider.instance,
        StrengthSetDataProvider.instance,
        PlatformDataProvider.instance,
        PlatformCredentialDataProvider.instance,
        ActionProviderDataProvider.instance,
        ActionDataProvider.instance,
        ActionRuleDataProvider.instance,
        ActionEventDataProvider.instance,
      ];
}
