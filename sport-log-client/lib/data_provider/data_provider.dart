import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/models/account_data/account_data.dart';

final _logger = Logger('DP');

void resultSink(Result<dynamic, dynamic> result) {
  if (result.isFailure) {
    _logger.e('Got result with failure.', result.failure, StackTrace.current);
  }
}

abstract class DataProvider<T> extends ChangeNotifier {
  Future<void> createSingle(T object);

  Future<void> updateSingle(T object);

  Future<void> deleteSingle(T object);

  Future<List<T>> getNonDeleted();

  Future<void> pushToServer();

  /// only called if internet connection is needed
  /// (call [handleApiError] with isCritical = true)
  VoidCallback? _onNoInternetNeeded;

  void handleApiError(ApiError error, {bool isCritical = false}) {
    if (isCritical) {
      _logger.e('Api error: ${error.toErrorMessage()}', error);
      if (error == ApiError.noInternetConnection &&
          _onNoInternetNeeded != null) {
        _onNoInternetNeeded!();
      } else {
        throw error;
      }
    } else {
      _logger.i('Api error: ${error.toErrorMessage()}');
    }
  }

  void onNoInternetConnection(VoidCallback? callback) {
    _onNoInternetNeeded = callback;
  }

  Future<void> doFullUpdate();

  Future<void> upsertPartOfAccountData(AccountData accountData);
}

abstract class DataProviderImpl<T extends DbObject> extends DataProvider<T> {
  ApiAccessor<T> get api;

  DbAccessor<T> get db;

  List<T> getFromAccountData(AccountData accountData);

  @override
  Future<List<T>> getNonDeleted() async => db.getNonDeleted();

  @override
  Future<void> pushToServer() async {
    await Future.wait([
      _pushUpdatedToServer(),
      _pushCreatedToServer(),
    ]);
  }

  // TODO: this makes only sense with UnconnectedMethods
  Future<void> _pushUpdatedToServer() async {
    final recordsToUpdate = await db.getWithSyncStatus(SyncStatus.updated);
    final result = await api.putMultiple(recordsToUpdate);
    if (result.isFailure) {
      handleApiError(result.failure);
      return;
    }
    db.setAllUpdatedSynchronized();
  }

  Future<void> _pushCreatedToServer() async {
    final recordsToCreate = await db.getWithSyncStatus(SyncStatus.created);
    final result = await api.postMultiple(recordsToCreate);
    if (result.isFailure) {
      handleApiError(result.failure);
      return;
    }
    db.setAllCreatedSynchronized();
  }

  Future<T?> getById(Int64 id) async => db.getSingle(id);

  @override
  Future<void> doFullUpdate() async {
    final result = await api.getMultiple();
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    await upsertMultiple(result.success, synchronized: true);
  }

  Future<void> upsertMultiple(List<T> objects,
      {required bool synchronized}) async {
    if (objects.isEmpty) {
      return;
    }
    await db.upsertMultiple(objects, synchronized: synchronized);
    notifyListeners();
  }

  @override
  Future<void> upsertPartOfAccountData(AccountData accountData) async {
    await upsertMultiple(getFromAccountData(accountData), synchronized: true);
  }
}

mixin ConnectedMethods<T extends DbObject> on DataProviderImpl<T> {
  @override
  Future<void> createSingle(T object) async {
    assert(object.isValid());
    final result = await api.postSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    db
        .createSingle(object, isSynchronized: true)
        .then((_) => notifyListeners());
  }

  @override
  Future<void> updateSingle(T object) async {
    assert(object.isValid());
    final result = await api.putSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    db
        .updateSingle(object, isSynchronized: true)
        .then((_) => notifyListeners());
  }

  @override
  Future<void> deleteSingle(T object) async {
    final result = await api.putSingle(object..deleted = true);
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    db
        .deleteSingle(object.id, isSynchronized: true)
        .then((_) => notifyListeners());
  }
}

mixin UnconnectedMethods<T extends DbObject> on DataProviderImpl<T> {
  @override
  Future<void> createSingle(T object) async {
    assert(object.isValid());
    // TODO: catch errors
    await db.createSingle(object);
    notifyListeners();
    api.postSingle(object).then((result) {
      if (result.isFailure) {
        // TODO: what if request fails due to conflict (when connected to internet)?
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id);
      }
    });
  }

  @override
  Future<void> updateSingle(T object) async {
    assert(object.isValid());
    // TODO: catch errors
    await db.updateSingle(object);
    notifyListeners();
    api.putSingle(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id);
      }
    });
  }

  @override
  Future<void> deleteSingle(T object) async {
    // TODO: catch errors
    await db.deleteSingle(object.id);
    notifyListeners();
    api.putSingle(object..deleted = true).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id);
      }
    });
  }
}
