
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';

import 'all.dart';

class MetconDescription implements Validatable {
  MetconDescription({
    required this.metcon,
    required this.moves,
    required this.isDeletable,
  });

  Metcon metcon;
  List<MetconMovement> moves;
  bool isDeletable;

  @override
  bool isValid() {
    return metcon.isValid()
        && moves.isNotEmpty
        && moves.every((mm) => mm.metconId == metcon.id)
        && moves.everyIndexed((mm, index) => mm.movementNumber == index)
        && moves.every((mm) => mm.isValid());
  }
}