
import 'movement.dart';

class UiMovement {
  UiMovement({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.description,
  });

  int? id;
  int? userId;
  String name;
  MovementCategory category;
  String? description;

  UiMovement.fromMovement(Movement movement)
    : id = movement.id,
      userId = movement.userId,
      name = movement.name,
      category = movement.category,
      description = movement.description;
}