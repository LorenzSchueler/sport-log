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

  static Future<void> handleApiError(
    ApiError error, {
    VoidCallback? onNoInternet,
  }) async {
    _logger.e('Api error: $error', error.errorCode);
    switch (error.errorCode) {
      case ApiErrorCode.serverUnreachable:
        _logger.i("on no internet: $onNoInternet");
        onNoInternet?.call();
        break;
      case ApiErrorCode.unauthorized:
        _logger.w('Tried sync but access unauthorized.', error);
        await showNewCredentialsDialog();
        break;
      default:
        await showMessageDialog(
          context: AppState.globalContext,
          title: "An error occured.",
          text: error.toString(),
        );
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

  @override
  Future<List<T>> getNonDeleted() async => db.getNonDeleted();

  @override
  Future<bool> pullFromServer() async {
    final result = await api.getMultiple();
    if (result.isFailure) {
      DataProvider.handleApiError(result.failure, onNoInternet: _onNoInternet);
      return false;
    } else {
      return await upsertMultiple(result.success, synchronized: true);
    }
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    final recordsToUpdate = await db.getWithSyncStatus(SyncStatus.updated);
    final result = await api.putMultiple(recordsToUpdate);
    if (result.isFailure) {
      DataProvider.handleApiError(result.failure);
      return false;
    }
    db.setAllUpdatedSynchronized();
    return true;
  }

  @override
  Future<bool> pushCreatedToServer() async {
    final recordsToCreate = await db.getWithSyncStatus(SyncStatus.created);
    final result = await api.postMultiple(recordsToCreate);
    if (result.isFailure) {
      DataProvider.handleApiError(result.failure);
      return false;
    }
    db.setAllCreatedSynchronized();
    return true;
  }

  Future<T?> getById(Int64 id) async => db.getSingle(id);

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
