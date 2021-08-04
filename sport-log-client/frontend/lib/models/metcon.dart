
import 'package:flutter/cupertino.dart';
import 'package:sport_log/models/movement.dart';

enum MetconType {
  amrap, emom, forTime
}

extension ToDisplayName on MetconType {
  String toDisplayName() {
    switch (this) {
      case MetconType.amrap:
        return "AMRAP";
      case MetconType.emom:
        return "EMOM";
      case MetconType.forTime:
        return "FOR TIME";
    }
  }
}

class Metcon {
  Metcon({
    required this.id,
    this.userId,
    this.name,
    required this.type,
    this.rounds,
    this.timecap,
    this.description
  });

  int id;
  int? userId;
  String? name;
  MetconType type;
  int? rounds;
  int? timecap; // seconds
  String? description;
}

class MetconMovement {
  MetconMovement({
    required this.id,
    required this.metconId,
    required this.movementId,
    required this.movementNumber,
    required this.count,
    required this.unit,
    this.weight,
  });

  int id;
  int metconId;
  int movementId;
  int movementNumber; // index within metcon
  int count;
  MovementUnit unit;
  double? weight;
}

class UiMetcon {
  UiMetcon({
    this.id,
    this.userId,
    this.name,
    required this.type,
    this.rounds,
    this.timecap,
    this.description,
    List<UiMetconMovement>? moves,
  }) : moves = moves ?? [];

  int? id;
  int? userId;
  String? name;
  MetconType type;
  int? rounds;
  Duration? timecap;
  String? description;
  List<UiMetconMovement> moves;

  UiMetcon.fromMetcon(Metcon m, this.moves)
    : id = m.id,
      userId = m.userId,
      name = m.name,
      type = m.type,
      rounds = m.rounds,
      timecap = (m.timecap != null) ? Duration(seconds: m.timecap!) : null,
      description = m.description;

  Metcon toMetcon() {
    assert(id != null);
    return Metcon(
      id: id!,
      userId: userId,
      name: name,
      type: type,
      rounds: rounds,
      timecap: timecap?.inSeconds,
      description: description,
    );
  }
}

class UiMetconMovement {
  UiMetconMovement({
    this.id,
    this.metconId,
    required this.movementId,
    required this.count,
    required this.unit,
    this.weight,
  });

  int? id;
  int? metconId;
  int movementId;
  int count;
  MovementUnit unit;
  double? weight;

  UiMetconMovement.fromMetconMovement(MetconMovement mm)
    : id = mm.id,
      metconId = mm.metconId,
      movementId = mm.movementId,
      count = mm.count,
      unit = mm.unit,
      weight = mm.weight;

  MetconMovement toMetconMovement(Metcon metcon, int movementNumber) {
    assert(id != null);
    return MetconMovement(
      id: id!,
      metconId: metcon.id,
      movementId: movementId,
      movementNumber: movementNumber,
      count: count,
      unit: unit,
      weight: weight,
    );
  }
}