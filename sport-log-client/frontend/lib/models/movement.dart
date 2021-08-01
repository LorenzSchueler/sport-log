
enum MovementUnit {
  reps, cal, meter, km, yard, foot, mile
}

enum MovementCategory {
  strength, cardio
}

class NewMovement {
  NewMovement({
    required this.name,
    required this.category,
    this.description,
  });

  String name;
  MovementCategory category;
  String? description;
}

class Movement {
  Movement({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.description,
  });

  int id;
  int? userId;
  String name;
  MovementCategory category;
  String? description;

  Movement.fromNewMovement(NewMovement nm, this.id)
    : name = nm.name, userId = 1,
      description = nm.description, category = nm.category;
}