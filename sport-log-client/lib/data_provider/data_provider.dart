import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/logger.dart';

final _logger = Logger('DP');

void resultSink(Result<dynamic, dynamic> result) {
  if (result.isFailure) {
    _logger.e('Got result with failure.', result.failure, StackTrace.current);
  }
}

abstract class DataProvider<T> {
  Future<void> createSingle(T object);
  Future<void> updateSingle(T object);
  Future<void> deleteSingle(T object);

  Future<List<T>> getNonDeleted();
  Future<void> pushToServer();

  void handleApiError(ApiError error) {
    _logger.w('Got an api error.', error);
  }

  void handleDbError(DbError error) {
    _logger.e('Got a database error.', error);
  }
}

abstract class DataProviderImpl<T extends DbObject> extends DataProvider<T> {
  ApiAccessor<T> get api;
  Table<T> get db;

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
    final apiResult = await api.putMultiple(recordsToUpdate);
    if (apiResult.isFailure) {
      handleApiError(apiResult.failure);
      return;
    }
    db.setAllUpdatedSynchronized();
  }

  Future<void> _pushCreatedToServer() async {
    final recordsToCreate = await db.getWithSyncStatus(SyncStatus.created);
    final apiResult = await api.postMultiple(recordsToCreate);
    if (apiResult.isFailure) {
      handleApiError(apiResult.failure);
      return;
    }
    db.setAllCreatedSynchronized();
  }

  Future<T?> getById(Int64 id) async => db.getSingle(id);
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
    db.createSingle(object, isSynchronized: true);
  }

  @override
  Future<void> updateSingle(T object) async {
    assert(object.isValid());
    final result = await api.putSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    db.updateSingle(object, isSynchronized: true);
  }

  @override
  Future<void> deleteSingle(T object) async {
    final result = await api.putSingle(object..deleted = true);
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    db.deleteSingle(object.id, isSynchronized: true);
  }
}

mixin UnconnectedMethods<T extends DbObject> on DataProviderImpl<T> {
  @override
  Future<void> createSingle(T object) async {
    assert(object.isValid());
    // TODO: catch errors
    await db.createSingle(object);
    api.postSingle(object).then((result) {
      if (result.isFailure) {
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
    api.putSingle(object..deleted = true).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id);
      }
    });
  }
}
