import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/database/database.dart';
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
  Future<DbResult> createSingle(T object);

  Future<DbResult> updateSingle(T object);

  Future<DbResult> deleteSingle(T object);

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
  Future<DbResult> createSingle(T object) async {
    assert(object.isValid());
    final result = await db.createSingle(object);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
  }

  @override
  Future<DbResult> updateSingle(T object) async {
    assert(object.isValid());
    final result = await db.updateSingle(object);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
  }

  @override
  Future<DbResult> deleteSingle(T object) async {
    final result = await db.deleteSingle(object.id);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
  }

  Future<DbResult> createMultiple(List<T> objects) async {
    assert(objects.every((element) => element.isValid()));
    final result = await db.createMultiple(objects);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
  }

  Future<DbResult> updateMultiple(List<T> objects) async {
    assert(objects.every((element) => element.isValid()));
    final result = await db.updateMultiple(objects);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
  }

  Future<DbResult> deleteMultiple(List<T> objects) async {
    final result = await db.deleteMultiple(objects);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
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
      return (await upsertMultiple(result.success, synchronized: true))
          .isSuccess();
    }
  }

  Future<bool> _resolveConflict(
    ConflictResolution conflictResolution,
    ApiResult<void> Function(T) fnSingle,
    List<T> records,
  ) async {
    switch (conflictResolution) {
      case ConflictResolution.automatic:
        _logger.w("solving conflict automatically");
        for (final record in records) {
          // check if this record causes a conflict
          final result = await fnSingle(record);
          // if record causes conflict delete it
          if (result.isFailure) {
            _logger.w("hard deleting record $record");
            db.hardDeleteSingle(record.id);
          }
        }
        return true; // all entries can be set to synchronized
      case ConflictResolution.manual:
        _logger.w("solving conflict manually");
        return false; // Entries cannot be set to synchronized yet. There are still conflicts.
    }
  }

  Future<bool> _pushEntriesToServer(
    ApiResult<void> Function(List<T>) fnMultiple,
    ApiResult<void> Function(T) fnSingle,
    List<T> records,
  ) async {
    final result = await fnMultiple(records);
    if (result.isFailure) {
      final conflictResolution =
          await DataProvider.handleApiError(result.failure);
      if (conflictResolution != null) {
        return await _resolveConflict(conflictResolution, fnSingle, records);
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    final recordsToUpdate = await db.getWithSyncStatus(SyncStatus.updated);
    if (await _pushEntriesToServer(
      api.putMultiple,
      api.putSingle,
      recordsToUpdate,
    )) {
      await db.setAllUpdatedSynchronized();
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> pushCreatedToServer() async {
    final recordsToCreate = await db.getWithSyncStatus(SyncStatus.created);
    if (await _pushEntriesToServer(
      api.postMultiple,
      api.postSingle,
      recordsToCreate,
    )) {
      await db.setAllCreatedSynchronized();
      return true;
    } else {
      return false;
    }
  }

  Future<T?> getById(Int64 id) async => db.getById(id);

  Future<DbResult> upsertFromAccountData(AccountData accountData) async {
    return await upsertMultiple(
      getFromAccountData(accountData),
      synchronized: true,
    );
  }

  Future<DbResult> upsertMultiple(
    List<T> objects, {
    required bool synchronized,
  }) async {
    if (objects.isEmpty) {
      return DbResult.success();
    }
    final result = await db.upsertMultiple(objects, synchronized: synchronized);
    if (result.isFailure()) {
      return result;
    }
    notifyListeners();
    return DbResult.success();
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
