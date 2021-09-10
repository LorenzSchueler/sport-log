import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/extensions/result_extension.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconDataProvider extends DataProvider<MetconDescription> {
  final api = Api.instance.metcons;

  final db = AppDatabase.instance!.metcons;
  final metconMovements = AppDatabase.instance!.metconMovements;

  @override
  Future<bool> createSingle(MetconDescription object) async {
    assert(object.isValid());
    final result = await db.createFull(object);
    if (result.isFailure) {
      handleDbError(result.failure);
      return false;
    }
    api.postFull(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.metcon.id).then(resultSink);
      }
    });
    return true;
  }

  @override
  Future<bool> deleteSingle(MetconDescription object) async {
    final result = await db.deleteSingle(object.metcon.id);
    if (result.isFailure) {
      handleDbError(result.failure);
      return false;
    }
    api.putFull(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.metcon.id).then(resultSink);
      }
    });
    return true;
  }

  @override
  Future<List<MetconDescription>> getNonDeleted() async {
    return (await db.getNonDeletedFull()).orDo((e) {
      handleDbError(e);
      return [];
    });
  }

  @override
  Future<void> pushToServer() async {
    await Future.wait([
      _pushUpdatedToServer(),
      _pushCreatedToServer(),
    ]);
  }

  Future<void> _pushUpdatedToServer() async {
    final dbResult1 = await db.getWithSyncStatus(SyncStatus.updated);
    if (dbResult1.isFailure) {
      handleDbError(dbResult1.failure);
      return;
    }
    final apiResult1 = await api.putMultiple(dbResult1.success);
    if (apiResult1.isFailure) {
      handleApiError(apiResult1.failure);
      return;
    }
    db.setAllUpdatedSynchronized().then(resultSink);

    final dbResult2 =
        await metconMovements.getWithSyncStatus(SyncStatus.updated);
    if (dbResult2.isFailure) {
      handleDbError(dbResult2.failure);
      return;
    }
    final apiResult2 = await api.putMultiple(dbResult1.success);
    if (apiResult2.isFailure) {
      handleApiError(apiResult2.failure);
      return;
    }
    metconMovements.setAllUpdatedSynchronized().then(resultSink);
  }

  Future<void> _pushCreatedToServer() async {
    final dbResult1 = await db.getWithSyncStatus(SyncStatus.created);
    if (dbResult1.isFailure) {
      handleDbError(dbResult1.failure);
      return;
    }
    final apiResult1 = await api.postMultiple(dbResult1.success);
    if (apiResult1.isFailure) {
      handleApiError(apiResult1.failure);
      return;
    }
    db.setAllCreatedSynchronized().then(resultSink);

    final dbResult2 =
        await metconMovements.getWithSyncStatus(SyncStatus.created);
    if (dbResult2.isFailure) {
      handleDbError(dbResult2.failure);
      return;
    }
    final apiResult2 = await api.postMultiple(dbResult1.success);
    if (apiResult2.isFailure) {
      handleApiError(apiResult2.failure);
      return;
    }
    metconMovements.setAllCreatedSynchronized().then(resultSink);
  }

  @override
  Future<bool> updateSingle(MetconDescription object) async {
    final result = await db.updateFull(object);
    if (result.isFailure) {
      handleDbError(result.failure);
      return false;
    }
    api.putFull(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.metcon.id).then(resultSink);
      }
    });
    return true;
  }
}
