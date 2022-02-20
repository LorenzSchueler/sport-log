import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/widgets/form_widgets/new_credentials_dialog.dart';

final _logger = Logger('DataProvider');

abstract class DataProvider<T> extends ChangeNotifier {
  Future<void> createSingle(T object);

  Future<void> updateSingle(T object);

  Future<void> deleteSingle(T object);

  Future<List<T>> getNonDeleted();

  Future<void> pushUpdatedToServer();

  Future<void> pushCreatedToServer();

  Future<void> doFullUpdate(); // used in page refresh

  Future<void> upsertFromAccountData(AccountData accountData);

  Future<void> pushToServer() async {
    await Future.wait([
      pushUpdatedToServer(),
      pushCreatedToServer(),
    ]);
  }

  /// only called if internet connection is needed
  /// (call [handleApiError] with isCritical = true)
  VoidCallback? _onNoInternet;

  set onNoInternetConnection(VoidCallback? callback) {
    _onNoInternet = callback;
  }

  void handleApiError(ApiError error, {bool isCritical = false}) async {
    if (isCritical) {
      _logger.e('Api error: ${error.toErrorMessage()}', error);
      if (error == ApiError.noInternetConnection && _onNoInternet != null) {
        _onNoInternet!();
      } else if (error == ApiError.unauthorized) {
        _logger.w('Tried sync but access unauthorized.', error);
        await showNewCredentialsDialog();
      }
    } else {
      _logger.i('Api error: ${error.toErrorMessage()}');
    }
  }
}

abstract class EntityDataProvider<T extends Entity> extends DataProvider<T> {
  Api<T> get api;

  TableAccessor<T> get db;

  List<T> getFromAccountData(AccountData accountData);

  @override
  Future<void> createSingle(T object) async {
    assert(object.isValid());
    // TODO: catch errors
    await db.createSingle(object);
    notifyListeners();
    final result = await api.postSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
    } else {
      db.setSynchronized(object.id);
    }
  }

  @override
  Future<void> updateSingle(T object) async {
    assert(object.isValid());
    // TODO: catch errors
    await db.updateSingle(object);
    notifyListeners();
    final result = await api.putSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
    } else {
      db.setSynchronized(object.id);
    }
  }

  @override
  Future<void> deleteSingle(T object) async {
    // TODO: catch errors
    await db.deleteSingle(object.id);
    notifyListeners();
    final result = await api.putSingle(object..deleted = true);
    if (result.isFailure) {
      handleApiError(result.failure);
    } else {
      db.setSynchronized(object.id);
    }
  }

  @override
  Future<List<T>> getNonDeleted() async => db.getNonDeleted();

  @override
  Future<void> doFullUpdate() async {
    final result = await api.getMultiple();
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    await upsertMultiple(result.success, synchronized: true);
  }

  @override
  Future<void> upsertFromAccountData(AccountData accountData) async {
    await upsertMultiple(getFromAccountData(accountData), synchronized: true);
  }

  @override
  Future<void> pushUpdatedToServer() async {
    final recordsToUpdate = await db.getWithSyncStatus(SyncStatus.updated);
    final result = await api.putMultiple(recordsToUpdate);
    if (result.isFailure) {
      handleApiError(result.failure);
      return;
    }
    db.setAllUpdatedSynchronized();
  }

  @override
  Future<void> pushCreatedToServer() async {
    final recordsToCreate = await db.getWithSyncStatus(SyncStatus.created);
    final result = await api.postMultiple(recordsToCreate);
    if (result.isFailure) {
      handleApiError(result.failure);
      return;
    }
    db.setAllCreatedSynchronized();
  }

  Future<T?> getById(Int64 id) async => db.getSingle(id);

  Future<void> upsertMultiple(List<T> objects,
      {required bool synchronized}) async {
    if (objects.isEmpty) {
      return;
    }
    await db.upsertMultiple(objects, synchronized: synchronized);
    notifyListeners();
  }

  static Future<void> pushAllToServer() async {
    // !!! order matters => no parallel execution possible
    for (final dp in EntityDataProvider.all) {
      await dp.pushToServer();
    }
  }

  static Future<void> upsertAccountData(AccountData data,
      {required bool synchronized}) async {
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
