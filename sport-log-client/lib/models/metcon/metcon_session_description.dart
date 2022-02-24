import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/metcon/metcon_session.dart';

class MetconSessionDescription implements Validatable {
  MetconSessionDescription({
    required this.metconSession,
    required this.metconDescription,
  });

  MetconSession metconSession;
  MetconDescription metconDescription;

  @override
  bool isValid() {
    return validate(
          metconDescription.isValid(),
          'MetconSessionDescription: metcon description not valid',
        ) &&
        validate(
          metconSession.metconId == metconDescription.metcon.id,
          'MetconSessionDescription: metcon id mismatch',
        );
  }

  String _resultDescription(bool short) {
    switch (metconDescription.metcon.metconType) {
      case MetconType.amrap:
        return "${metconSession.rounds} rounds + ${metconSession.reps} reps";
      case MetconType.emom:
        return "${metconDescription.metcon.rounds!} * ${(metconDescription.metcon.timecap!.inMinutes / metconDescription.metcon.rounds!).round()} min";
      case MetconType.forTime:
        if (short) {
          return metconSession.rounds == metconDescription.metcon.rounds
              ? "${formatTime(metconSession.time!, short: true)} min"
              : "${metconSession.rounds} rounds + ${metconSession.reps} reps";
        } else {
          return metconSession.rounds == metconDescription.metcon.rounds
              ? "${formatTime(metconSession.time!, short: true)} min (${formatTime(Duration(seconds: metconDescription.metcon.timecap!.inSeconds), short: true)} min)"
              : "${metconSession.rounds} rounds + ${metconSession.reps} reps (${metconDescription.metcon.rounds} rounds)";
        }
    }
  }

  String get longResultDescription {
    return _resultDescription(false);
  }

  String get shortResultDescription {
    return _resultDescription(true);
  }

  String get typeLengthDescription {
    return metconDescription.metcon.metconType == MetconType.forTime
        ? "${metconDescription.metcon.rounds!} Rounds ${metconDescription.metcon.metconType.displayName} (Timecap ${formatTime(metconDescription.metcon.timecap!, short: true)})"
        : "${metconDescription.metcon.metconType.displayName} ${formatTime(metconDescription.metcon.timecap!, short: true)}";
  }
}
