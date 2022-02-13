part of '../api.dart';

class MetconSessionApi extends Api<MetconSession> {
  @override
  MetconSession _fromJson(Map<String, dynamic> json) =>
      MetconSession.fromJson(json);

  @override
  String get _singularRoute => version + '/metcon_session';
}

class MetconApi extends Api<Metcon> {
  @override
  Metcon _fromJson(Map<String, dynamic> json) => Metcon.fromJson(json);

  @override
  String get _singularRoute => version + '/metcon';

  // TODO: put this into data provider?
  ApiResult<void> postFull(MetconDescription metconDescription) async {
    assert(metconDescription.isValid());
    final result1 = await postSingle(metconDescription.metcon);
    if (result1.isSuccess) {
      final result2 = await Api.metconMovements.postMultiple(
          metconDescription.moves.map((mmd) => mmd.metconMovement).toList());
      if (result2.isSuccess) {
        return Success(null);
      } else {
        return Failure(result2.failure);
      }
    } else {
      return Failure(result1.failure);
    }
  }

  // TODO: put this into data provider?
  // TODO: server deletes metcon movements automatically
  ApiResult<void> deleteFull(MetconDescription metconDescription) async {
    metconDescription.setDeleted();
    final result1 = await putSingle(metconDescription.metcon);
    if (result1.isSuccess) {
      final result2 = await Api.metconMovements.putMultiple(
          metconDescription.moves.map((mmd) => mmd.metconMovement).toList());
      if (result2.isSuccess) {
        return Success(null);
      } else {
        return Failure(result2.failure);
      }
    } else {
      return Failure(result1.failure);
    }
  }
}

class MetconMovementApi extends Api<MetconMovement> {
  @override
  MetconMovement _fromJson(Map<String, dynamic> json) =>
      MetconMovement.fromJson(json);

  @override
  String get _singularRoute => version + '/metcon_movement';
}
