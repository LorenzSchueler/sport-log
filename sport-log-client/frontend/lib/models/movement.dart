
enum MovementUnit {
  reps, cal, meter, km, yard, foot, mile
}

enum MovementCategory {
  strength, cardio
}

class NewMovement {
  NewMovement({
    required this.name,
    required this.description,
    required this.category,
  });

  String name;
  String description;
  MovementCategory category;
}

class Movement {
  Movement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  int id;
  String name;
  String description;
  MovementCategory category;

  Movement.fromNewMovement(NewMovement nm, this.id)
    : name = nm.name, description = nm.description, category = nm.category;
}