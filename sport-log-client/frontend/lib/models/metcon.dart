
import 'package:sport_log/models/movement.dart';

enum MetconType {
  amrap, emom, forTime
}

class MetconMovement {
  MetconMovement({
    required this.id,
    required this.movementId,
    required this.count,
    required this.unit,
    this.weight,
  });

  int id;
  int movementId;
  int count;
  MovementUnit unit;
  double? weight;

  MetconMovement.fromNewMetconMovement(NewMetconMovement nmm, this.id)
    : movementId = nmm.movementId,
      count = nmm.count,
      unit = nmm.unit,
      weight = nmm.weight;
}

class Metcon {
  Metcon({
    required this.id,
    required this.name,
    required this.type,
    this.rounds,
    this.timecap,
    this.description,
    required this.moves,
  });

  int id;
  String name;
  MetconType type;
  int? rounds;
  Duration? timecap;
  String? description;

  List<MetconMovement> moves;

  Metcon.fromNewMetconWithMoves(
      NewMetcon nm,
      this.id,
      this.moves
  ) : name = nm.name,
      type = nm.type,
      rounds = nm.rounds,
      timecap = nm.timecap,
      description = nm.description;
}

class NewMetconMovement {
  NewMetconMovement({
    required this.movementId,
    required this.count,
    required this.unit,
    this.weight,
  });

  int movementId;
  int count;
  MovementUnit unit;
  double? weight;
}

class NewMetcon {
  NewMetcon({
    required this.name,
    required this.type,
    this.rounds,
    this.timecap,
    this.description,
    required this.moves,
  });

  String name;
  MetconType type;
  int? rounds;
  Duration? timecap;
  String? description;

  List<NewMetconMovement> moves;
}