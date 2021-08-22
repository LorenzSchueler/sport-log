
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_set.dart';
import 'package:sport_log/helpers/validation.dart';

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
    return validate(strengthSession.isValid(),
            'StrengthSessionDescription: strength session not valid')
        && validate(strengthSets.isNotEmpty,
            'StrengthSessionDescription: strength sets empty')
        && validate(strengthSets.every((ss) => ss.strengthSessionId == strengthSession.id),
            'StrengthSessionDescription: strengthSessionId != strengthSession.id')
        && validate(strengthSets.everyIndexed((ss, index) => ss.setNumber == index),
            'StrengthSessionDescription: strengthSets indices wrong')
        && validate(strengthSets.every((ss) => ss.isValid()),
            'StrengthSessionDescription: strengthSets not valid')
        && validate(strengthSession.movementId == movement.id,
            'StrengthSessionDescription: movement id mismatch');
  }
}