import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'cardio_session_description.g.dart';

@JsonSerializable()
class CardioSessionDescription extends CompoundEntity {
  CardioSessionDescription({
    required this.cardioSession,
    required this.route,
    required this.movement,
  });

  CardioSession cardioSession;
  Route? route;
  Movement movement;

  CardioSessionDescription.defaultValue()
      : cardioSession = CardioSession.defaultValue(Movement.defaultMovement.id),
        movement = Movement.defaultMovement;

  factory CardioSessionDescription.fromJson(Map<String, dynamic> json) =>
      _$CardioSessionDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CardioSessionDescriptionToJson(this);

  @override
  CardioSessionDescription clone() => CardioSessionDescription(
        cardioSession: cardioSession.clone(),
        route: route?.clone(),
        movement: movement.clone(),
      );

  @override
  bool isValidBeforeSanitazion() {
    return cardioSession.isValidBeforeSanitazion() &&
        validate(
          route == null || route!.isValid(),
          'CardioSessionDescription: route is not valid',
        ) &&
        validate(
          route == null || cardioSession.routeId != null,
          'CardioSessionDescription: cardio session route id is null',
        ) &&
        validate(
          route == null || cardioSession.routeId! == route!.id,
          'CardioSessionDescription: route id mismatch',
        ) &&
        validate(
          movement.isValid(),
          'CardioSessionDescription: movement is not valid',
        ) &&
        validate(
          cardioSession.movementId == movement.id,
          'CardioSessionDescription: movement id mismatch',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion();
  }

  @override
  void sanitize() {
    cardioSession.sanitize();
    route?.sanitize();
  }
}
