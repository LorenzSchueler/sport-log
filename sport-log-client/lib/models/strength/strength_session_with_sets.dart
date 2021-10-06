import 'package:fixnum/fixnum.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_set.dart';

class StrengthSessionWithSets implements Validatable, HasId {
  StrengthSessionWithSets({
    required this.strengthSession,
    required this.movement,
    required this.strengthSets,
  });

  StrengthSession strengthSession;
  Movement movement;
  List<StrengthSet> strengthSets;

  @override
  bool isValid() {
    return validate(strengthSession.isValid(),
            'StrengthSessionDescription: strength session not valid') &&
        validate(strengthSets.isNotEmpty,
            'StrengthSessionDescription: strength sets empty') &&
        validate(
            strengthSets
                .every((ss) => ss.strengthSessionId == strengthSession.id),
            'StrengthSessionDescription: strengthSessionId != strengthSession.id') &&
        validate(
            strengthSets.everyIndexed((ss, index) => ss.setNumber == index),
            'StrengthSessionDescription: strengthSets indices wrong') &&
        validate(strengthSets.every((ss) => ss.isValid()),
            'StrengthSessionDescription: strengthSets not valid') &&
        validate(strengthSession.movementId == movement.id,
            'StrengthSessionDescription: movement id mismatch');
  }

  @override
  Int64 get id => strengthSession.id;

  void setDeleted() {
    strengthSession.deleted = true;
    for (final set in strengthSets) {
      set.deleted = true;
    }
  }

  StrengthSessionWithSets.defaultValue(this.movement, Int64 userId)
      : strengthSession = StrengthSession(
          id: randomId(),
          userId: userId,
          datetime: DateTime.now(),
          movementId: movement.id,
          interval: null,
          comments: null,
          deleted: false,
        ),
        strengthSets = [];
}
