
import 'package:sport_log/models/metcon.dart';
import 'package:sport_log/models/movement.dart';

class UiMetcon {
  UiMetcon({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    this.rounds,
    this.timecap,
    this.description,
    this.moves = const [],
  });

  int? id;
  int? userId;
  String name;
  MetconType type;
  int? rounds;
  Duration? timecap;
  String? description;
  List<UiMetconMovement> moves;
}

class UiMetconMovement {
  UiMetconMovement({
    this.id,
    this.metconId,
    required this.movement,
    required this.count,
    required this.unit,
    this.weight,
  });

  int? id;
  int? metconId;
  Movement movement;
  int count;
  MovementUnit unit;
  double? weight;
}