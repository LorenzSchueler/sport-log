import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/validation.dart';
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
    return validate(metconDescription.isValid(),
            'MetconSessionDescription: metcon description not valid') &&
        validate(metconSession.metconId == metconDescription.metcon.id,
            'MetconSessionDescription: metcon id mismatch');
  }

  String get name {
    return metconDescription.metcon.name ??
        metconDescription.moves.map((e) => e.movement.name).join(" & ");
  }

  String get shortResultDescription {
    switch (metconDescription.metcon.metconType) {
      case MetconType.amrap:
        return "${metconSession.rounds} rounds + ${metconSession.reps} reps";
        break;
      case MetconType.emom:
        return "${metconDescription.metcon.rounds!} * ${(metconDescription.metcon.timecap!.inMinutes / metconDescription.metcon.rounds!).round()} min";
        break;
      case MetconType.forTime:
        return metconSession.rounds == metconDescription.metcon.rounds
            ? "${formatTime(metconSession.time!, short: true)} min (${formatTime(metconDescription.metcon.timecap!.inSeconds, short: true)} min)"
            : "${metconSession.rounds} rounds + ${metconSession.reps} reps (${metconDescription.metcon.rounds} rounds)";
        break;
    }
  }
}
