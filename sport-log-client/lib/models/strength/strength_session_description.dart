import 'package:fixnum/fixnum.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_set.dart';

class StrengthSessionDescription implements Validatable, HasId {
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

  static bool areTheSame(
          StrengthSessionDescription ssd1, StrengthSessionDescription ssd2) =>
      ssd1.strengthSession.id == ssd2.strengthSession.id;
}
