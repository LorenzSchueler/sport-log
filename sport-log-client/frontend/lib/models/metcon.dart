
import 'package:sport_log/models/movement.dart';

enum MetconType {
  amrap, emom, forTime
}

class NewMetconMovement {
  NewMetconMovement({
    required this.movementId,
    required this.count,
    required this.unit,
    required this.weight,
  });

  int movementId;
  int count;
  MovementUnit unit;
  double weight;
}

class NewMetcon {
  NewMetcon({
    required this.name,
    required this.type,
    required this.rounds,
    required this.timecap,
    required this.moves,
  });

  String name;
  MetconType type;
  int rounds;
  Duration timecap;

  List<NewMetconMovement> moves;
}