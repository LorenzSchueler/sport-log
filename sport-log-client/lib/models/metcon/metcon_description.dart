import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/validation.dart';

import 'all.dart';

class MetconDescription implements Validatable {
  MetconDescription({
    required this.metcon,
    required this.moves,
    required this.hasReference,
  });

  Metcon metcon;
  List<MetconMovementDescription> moves;
  bool hasReference; // whether there is a MetconSession referencing this metcon

  String get name {
    return metcon.name ?? moves.map((e) => e.movement.name).join(" & ");
  }

  MetconDescription.defaultValue(Int64 userId)
      : metcon = Metcon.defaultValue(userId),
        moves = [],
        hasReference = false;

  @override
  bool isValid() {
    return validate(metcon.isValid(), 'MetconDescription: metcon not valid') &&
        validate(moves.isNotEmpty, 'MetconDescription: moves empty') &&
        validate(moves.every((mmd) => mmd.metconMovement.metconId == metcon.id),
            'MetconDescription: metcon id mismatch') &&
        validate(
            moves.everyIndexed(
                (mmd, index) => mmd.metconMovement.movementNumber == index),
            'MetconDescription: moves indices wrong') &&
        validate(moves.every((mm) => mm.isValid()),
            'MetconDescription: moves not valid');
  }

  static bool areTheSame(MetconDescription m1, MetconDescription m2) =>
      m1.metcon.id == m2.metcon.id;

  void setDeleted() {
    metcon.deleted = true;
    for (final move in moves) {
      move.metconMovement.deleted = true;
    }
  }

  Int64 get id => metcon.id;
}
