
import 'package:sport_log/helpers/iterable_extension.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_set.dart';
import 'package:sport_log/models/update_validatable.dart';

class StrengthSessionDescription implements UpdateValidatable {
  StrengthSessionDescription({
    required this.strengthSession,
    required this.strengthSets,
  });

  StrengthSession strengthSession;
  List<StrengthSet> strengthSets;

  @override
  bool validateOnUpdate() {
    return strengthSession.validateOnUpdate()
        && strengthSets.isNotEmpty
        && strengthSets.every((ss) => ss.strengthSessionId == strengthSession.id)
        && strengthSets.everyIndexed((ss, index) => ss.setNumber == index + 1)
        && strengthSets.every((ss) => ss.validateOnUpdate());
  }
}