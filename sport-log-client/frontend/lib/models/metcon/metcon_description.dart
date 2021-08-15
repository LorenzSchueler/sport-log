
import 'package:sport_log/helpers/update_validatable.dart';
import 'package:sport_log/helpers/iterable_extension.dart';

import 'all.dart';

class MetconDescription implements UpdateValidatable {
  MetconDescription({
    required this.metcon,
    required this.moves,
  });

  Metcon metcon;
  List<MetconMovement> moves;

  @override
  bool validateOnUpdate() {
    return metcon.validateOnUpdate()
        && moves.isNotEmpty
        && moves.every((mm) => mm.metconId == metcon.id)
        && moves.everyIndexed((mm, index) => mm.movementNumber == index + 1)
        && moves.every((mm) => mm.validateOnUpdate());
  }
}