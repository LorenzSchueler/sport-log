
import 'package:fixnum/fixnum.dart';

import 'movement.dart';

class UiMovement {
  UiMovement({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.description,
  });

  Int64? id;
  Int64? userId;
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