part of '../api.dart';

class MetconSessionApi extends ApiAccessor<MetconSession> {
  @override
  MetconSession fromJson(Map<String, dynamic> json) =>
      MetconSession.fromJson(json);

  @override
  String get singularRoute => version + '/metcon_session';

  @override
  Map<String, dynamic> toJson(MetconSession object) => object.toJson();
}

class MetconApi extends ApiAccessor<Metcon> {
  @override
  Metcon fromJson(Map<String, dynamic> json) => Metcon.fromJson(json);

  @override
  String get singularRoute => version + '/metcon';

  @override
  Map<String, dynamic> toJson(Metcon object) => object.toJson();

  ApiResult<void> postFull(MetconDescription metconDescription) async {
    assert(metconDescription.isValid());
    final result1 = await postSingle(metconDescription.metcon);
    if (result1.isSuccess) {
      final result2 = await Api.instance.metconMovements
          .postMultiple(metconDescription.moves);
      if (result2.isSuccess) {
        return Success(null);
      } else {
        return Failure(result2.failure);
      }
    } else {
      return Failure(result1.failure);
    }
  }

  ApiResult<void> putFull(MetconDescription metconDescription) async {
    final result1 = await putSingle(metconDescription.metcon);
    if (result1.isSuccess) {
      final result2 = await Api.instance.metconMovements
          .putMultiple(metconDescription.moves);
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

class MetconMovementApi extends ApiAccessor<MetconMovement> {
  @override
  MetconMovement fromJson(Map<String, dynamic> json) =>
      MetconMovement.fromJson(json);

  @override
  String get singularRoute => version + '/metcon_movement';

  @override
  Map<String, dynamic> toJson(MetconMovement object) => object.toJson();
}
