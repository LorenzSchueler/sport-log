
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';

import 'all.dart';

class MetconDescription implements Validatable {
  MetconDescription({
    required this.metcon,
    required this.moves,
    required this.hasReference,
  });

  Metcon metcon;
  List<MetconMovement> moves;
  bool hasReference; // whether there is a MetconSession referencing this metcon

  @override
  bool isValid() {
    return validate(metcon.isValid(), 'MetconDescription: metcon not valid')
        && validate(moves.isNotEmpty, 'MetconDescription: moves empty')
        && validate(moves.every((mm) => mm.metconId == metcon.id),
            'MetconDescription: metcon id mismatch')
        && validate(moves.everyIndexed((mm, index) => mm.movementNumber == index),
            'MetconDescription: moves indices wrong')
        && validate(moves.every((mm) => mm.isValid()),
            'MetconDescription: moves not valid');
  }
}