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

  static CardioSessionDescription defaultValue() {
    final movement = Movement.defaultMovement;
    return CardioSessionDescription(
      cardioSession: CardioSession.defaultValue(movement.id),
      route: null,
      movement: movement,
    );
  }

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
  bool isValid() {
    return cardioSession.isValid() &&
        (route == null ||
            validate(
              route!.isValid(),
              'CardioSessionDescription: route is not valid',
            )) &&
        (route == null ||
            validate(
              cardioSession.routeId != null,
              'CardioSessionDescription: cardio session route id is null',
            )) &&
        (route == null ||
            validate(
              cardioSession.routeId! == route!.id,
              'CardioSessionDescription: route id mismatch',
            )) &&
        validate(
          movement.isValid(),
          'CardioSessionDescription: movement is not valid',
        ) &&
        validate(
          cardioSession.movementId == movement.id,
          'CardioSessionDescription: movement id mismatch',
        );
  }
}
