
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/models/movement/movement.dart';

import 'metcon.dart';
import 'metcon_movement.dart';

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
    required this.deleted,
  }) : moves = moves ?? [];

  Int64? id;
  Int64? userId;
  String? name;
  MetconType type;
  int? rounds;
  Duration? timecap;
  String? description;
  List<UiMetconMovement> moves;
  bool deleted;

  UiMetcon.fromMetcon(Metcon m, this.moves)
      : id = m.id,
        userId = m.userId,
        name = m.name,
        type = m.metconType,
        rounds = m.rounds,
        timecap = (m.timecap != null) ? Duration(seconds: m.timecap!) : null,
        description = m.description,
        deleted = m.deleted;

  Metcon toMetcon() {
    assert(id != null);
    return Metcon(
      id: id!,
      userId: userId,
      name: name,
      metconType: type,
      rounds: rounds,
      timecap: timecap?.inSeconds,
      description: description,
      deleted: deleted,
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
    required this.deleted,
  });

  Int64? id;
  Int64? metconId;
  Int64 movementId;
  int count;
  MovementUnit unit;
  double? weight;
  bool deleted;

  UiMetconMovement.fromMetconMovement(MetconMovement mm)
      : id = mm.id,
        metconId = mm.metconId,
        movementId = mm.movementId,
        count = mm.count,
        unit = mm.unit,
        weight = mm.weight,
        deleted = mm.deleted;

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
      deleted: deleted,
    );
  }
}
