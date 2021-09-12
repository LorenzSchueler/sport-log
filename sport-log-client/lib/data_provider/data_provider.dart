import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/extensions/result_extension.dart';
import 'package:sport_log/helpers/logger.dart';

final logger = Logger('DP');

void resultSink(Result<dynamic, dynamic> result) {
  if (result.isFailure) {
    logger.e('Got result with failure.', result.failure, StackTrace.current);
  }
}

abstract class DataProvider<T> {
  Future<void> createSingle(T object);
  Future<void> updateSingle(T object);
  Future<void> deleteSingle(T object);

  Future<List<T>> getNonDeleted();
  Future<void> pushToServer();

  void handleApiError(ApiError error) {
    logger.e('Got an api error.', error);
  }

  void handleDbError(DbError error) {
    logger.e('Got a database error.', error);
  }
}

abstract class DataProviderImpl<T extends DbObject> extends DataProvider<T> {
  ApiAccessor<T> get api;
  Table<T> get db;

  @override
  Future<List<T>> getNonDeleted() async {
    final result = await db.getNonDeleted();
    if (result.isFailure) {
      handleDbError(result.failure);
      return [];
    }
    return result.success;
  }

  @override
  Future<void> pushToServer() async {
    await Future.wait([
      _pushUpdatedToServer(),
      _pushCreatedToServer(),
    ]);
  }

  Future<void> _pushUpdatedToServer() async {
    final dbResult = await db.getWithSyncStatus(SyncStatus.updated);
    if (dbResult.isFailure) {
      handleDbError(dbResult.failure);
      return;
    }
    final apiResult = await api.putMultiple(dbResult.success);
    if (apiResult.isFailure) {
      handleApiError(apiResult.failure);
      return;
    }
    db.setAllUpdatedSynchronized().then(resultSink);
  }

  Future<void> _pushCreatedToServer() async {
    final dbResult = await db.getWithSyncStatus(SyncStatus.created);
    if (dbResult.isFailure) {
      handleDbError(dbResult.failure);
      return;
    }
    final apiResult = await api.postMultiple(dbResult.success);
    if (apiResult.isFailure) {
      handleApiError(apiResult.failure);
      return;
    }
    db.setAllCreatedSynchronized().then(resultSink);
  }

  Future<T?> getById(Int64 id) async {
    (await db.getSingle(id)).orDo((e) {
      handleDbError(e);
      return null;
    });
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
    db.createSingle(object, isSynchronized: true).then(resultSink);
  }

  @override
  Future<void> updateSingle(T object) async {
    assert(object.deleted || object.isValid());
    final result = await api.putSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
      throw result.failure;
    }
    db.updateSingle(object, isSynchronized: true).then(resultSink);
  }

  @override
  Future<void> deleteSingle(T object) async {
    return updateSingle(object..deleted = true);
  }
}

mixin UnconnectedMethods<T extends DbObject> on DataProviderImpl<T> {
  @override
  Future<void> createSingle(T object) async {
    assert(object.isValid());
    final result = await db.createSingle(object);
    if (result.isFailure) {
      handleDbError(result.failure);
      throw result.failure;
    }
    api.postSingle(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id).then(resultSink);
      }
    });
  }

  @override
  Future<void> updateSingle(T object) async {
    assert(object.deleted || object.isValid());
    final result = await db.updateSingle(object);
    if (result.isFailure) {
      handleDbError(result.failure);
      throw result.failure;
    }
    api.putSingle(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id).then(resultSink);
      }
    });
  }

  @override
  Future<void> deleteSingle(T object) async {
    return updateSingle(object..deleted = true);
  }
}
