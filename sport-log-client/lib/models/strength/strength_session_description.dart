
import 'package:sport_log/helpers/iterable_extension.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_set.dart';
import 'package:sport_log/helpers/update_validatable.dart';

class StrengthSessionDescription implements Validatable {
  StrengthSessionDescription({
    required this.strengthSession,
    required this.strengthSets,
    required this.movement,
  });

  StrengthSession strengthSession;
  List<StrengthSet> strengthSets;
  Movement movement;

  @override
  bool isValid() {
    return strengthSession.isValid()
        && strengthSets.isNotEmpty
        && strengthSets.every((ss) => ss.strengthSessionId == strengthSession.id)
        && strengthSets.everyIndexed((ss, index) => ss.setNumber == index)
        && strengthSets.every((ss) => ss.isValid())
        && strengthSession.movementId == movement.id;
  }
}