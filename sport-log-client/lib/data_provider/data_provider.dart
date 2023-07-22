import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, VoidCallback;
import 'package:sport_log/api/accessors/account_data_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/platform_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/wod_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/dialogs/new_credentials_dialog.dart';

final _logger = Logger('DataProvider');

abstract class DataProvider<T> extends ChangeNotifier {
  Future<DbResult> createSingle(T object);

  Future<DbResult> updateSingle(T object);

  Future<DbResult> deleteSingle(T object);

  Future<List<T>> getNonDeleted();

  static Future<ConflictResolution?> handleApiError(
    ApiError error,
    VoidCallback? onNoInternet,
  ) async {
    _logger.e('Api error: $error', error.errorType);
    switch (error.errorType) {
      case ApiErrorType.serverUnreachable:
        _logger.i("on no internet != null: ${onNoInternet != null}");
        onNoInternet?.call();
        return null;
      case ApiErrorType.unauthorized:
        _logger.w('Tried sync but access unauthorized.', error);
        unawaited(showNewCredentialsDialog());
        return null;
      // primary foreign or unique key violation
      case ApiErrorType.conflict:
        final conflictResolution = await showConflictDialog(
          context: App.globalContext,
          title: "An Error Occurred",
          text: error.toString(),
        );
        _logger.i(conflictResolution);
        return conflictResolution;
      // ignore: no_default_cases
      default:
        await showMessageDialog(
          context: App.globalContext,
          title: "An Error Occurred",
          text: error.toString(),
        );
        return null;
    }
  }

  static Future<void> _handleDbError(
    DbError error,
  ) async {
    _logger.e('Db error: $error');
    await showMessageDialog(
      context: App.globalContext,
      title: "An Error Occurred",
      text: error.toString(),
    );
  }
}

abstract class EntityDataProvider<T extends AtomicEntity>
    extends DataProvider<T> {
  Api<T> get api;

  TableAccessor<T> get table;

  List<T> getFromAccountData(AccountData accountData);

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Future<DbResult> createSingle(T object, {bool notify = true}) async {
    object.sanitize();
    assert(object.isValid());
    final result = await table.createSingle(object);
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result;
  }

  @override
  Future<DbResult> updateSingle(T object, {bool notify = true}) async {
    object.sanitize();
    assert(object.isValid());
    final result = await table.updateSingle(object);
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result;
  }

  @override
  Future<DbResult> deleteSingle(T object, {bool notify = true}) async {
    final result = await table.deleteSingle(object.id);
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result;
  }

  @override
  Future<List<T>> getNonDeleted() async => table.getNonDeleted();

  /// used in compound data providers impl of createSingle
  Future<DbResult> createMultiple(List<T> objects, {bool notify = true}) async {
    for (final object in objects) {
      object.sanitize();
    }
    assert(objects.every((object) => object.isValid()));
    final result = await table.createMultiple(objects);
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result;
  }

  /// used in compound data providers impl of updateSingle
  Future<DbResult> updateMultiple(List<T> objects, {bool notify = true}) async {
    for (final object in objects) {
      object.sanitize();
    }
    assert(objects.every((object) => object.isValid()));
    final result = await table.updateMultiple(objects);
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result;
  }

  /// used in compound data providers impl of deleteSingle
  Future<DbResult> deleteMultiple(List<T> objects, {bool notify = true}) async {
    final result = await table.deleteMultiple(objects);
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result;
  }

  Future<T?> getById(Int64 id) async => table.getById(id);

  Future<bool> _resolveConflict(
    ConflictResolution conflictResolution,
    Future<ApiResult<void>> Function(T) fnSingle,
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
            await table.hardDeleteSingle(record.id);
          }
        }
        return true; // all entries can be set to synchronized
      case ConflictResolution.manual:
        _logger.w("solving conflict manually");
        return false; // Entries cannot be set to synchronized yet. There are still conflicts.
    }
  }

  Future<bool> _pushEntriesToServer(
    Future<ApiResult<void>> Function(List<T>) fnMultiple,
    Future<ApiResult<void>> Function(T) fnSingle,
    List<T> records,
    VoidCallback? onNoInternet,
  ) async {
    final result = await fnMultiple(records);
    if (result.isFailure) {
      final conflictResolution =
          await DataProvider.handleApiError(result.failure, onNoInternet);
      return conflictResolution != null
          ? await _resolveConflict(conflictResolution, fnSingle, records)
          : false;
    } else {
      return true;
    }
  }

  Future<bool> _pushUpdatedToServer(VoidCallback? onNoInternet) async {
    final recordsToUpdate = await table.getWithSyncStatus(SyncStatus.updated);
    final success = await _pushEntriesToServer(
      api.putMultiple,
      api.putSingle,
      recordsToUpdate,
      onNoInternet,
    );
    if (success) {
      await table.setAllUpdatedSynchronized();
    }
    return success;
  }

  Future<bool> _pushCreatedToServer(VoidCallback? onNoInternet) async {
    final recordsToCreate = await table.getWithSyncStatus(SyncStatus.created);
    final success = await _pushEntriesToServer(
      api.postMultiple,
      api.postSingle,
      recordsToCreate,
      onNoInternet,
    );
    if (success) {
      await table.setAllCreatedSynchronized();
    }
    return success;
  }

  Future<bool> _pushToServer(VoidCallback? onNoInternet) async {
    return (await Future.wait([
      _pushUpdatedToServer(onNoInternet),
      _pushCreatedToServer(onNoInternet),
    ]))
        .every((result) => result);
  }

  Future<bool> _upsertMultiple(
    List<T> objects, {
    required bool synchronized,
    bool notify = true,
  }) async {
    if (objects.isEmpty) {
      return true;
    }
    final result =
        await table.upsertMultiple(objects, synchronized: synchronized);
    if (result.isFailure) {
      await DataProvider._handleDbError(result.failure);
    }
    if (result.isSuccess && notify && !_disposed) {
      notifyListeners();
    }
    return result.isSuccess;
  }

  static Future<bool> upSync({required VoidCallback? onNoInternet}) async {
    // order matters => no parallel execution possible
    for (final dp in EntityDataProvider.all) {
      if (!await dp._pushToServer(onNoInternet)) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> downSync({required VoidCallback? onNoInternet}) async {
    final accountDataResult =
        await AccountDataApi().get(Settings.instance.lastSync);
    if (accountDataResult.isFailure) {
      await DataProvider.handleApiError(
        accountDataResult.failure,
        onNoInternet,
      );
      return false;
    } else {
      final accountData = accountDataResult.success;
      if (accountData.user != null) {
        await Account.updateUserFromDownSync(accountData.user!);
      }
      // order matters => no parallel execution possible
      for (final dp in EntityDataProvider.all) {
        if (!await dp._upsertMultiple(
          dp.getFromAccountData(accountData),
          synchronized: true,
        )) {
          return false;
        }
      }
      return true;
    }
  }

  static List<EntityDataProvider> get all => [
        DiaryDataProvider(),
        WodDataProvider(),
        MovementDataProvider(),
        MetconDataProvider(),
        MetconMovementDataProvider(),
        MetconSessionDataProvider(),
        RouteDataProvider(),
        CardioSessionDataProvider(),
        StrengthSessionDataProvider(),
        StrengthSetDataProvider(),
        PlatformDataProvider(),
        PlatformCredentialDataProvider(),
        ActionProviderDataProvider(),
        ActionDataProvider(),
        ActionRuleDataProvider(),
        ActionEventDataProvider(),
      ];
}
