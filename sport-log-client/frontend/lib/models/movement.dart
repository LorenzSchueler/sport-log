
enum MovementUnit {
  reps, cal, meter, km, yard, foot, mile
}

enum MovementCategory {
  strength, cardio
}

class NewMovement {
  NewMovement({
    required this.name,
    this.description,
    required this.category,
  });

  String name;
  String? description;
  MovementCategory category;
}

class Movement {
  Movement({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.category,
  });

  int id;
  int? userId;
  String name;
  String? description;
  MovementCategory category;

  Movement.fromNewMovement(NewMovement nm, this.id)
    : name = nm.name, userId = 1,
      description = nm.description, category = nm.category;
}