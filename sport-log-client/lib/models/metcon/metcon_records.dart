import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/extensions/num_extension.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/metcon/metcon_session_description.dart';

typedef MetconRecords = Map<Int64, MetconRecord>;

extension MetconRecordsExtension on MetconRecords {
  bool getRecordTypes(
    MetconSessionDescription metconSessionDescription,
  ) {
    if (!metconSessionDescription.metconSession.rx) {
      return false;
    }
    final metconRecord =
        this[metconSessionDescription.metconDescription.metcon.id];
    if (metconRecord == null) {
      return false;
    }
    switch (metconSessionDescription.metconDescription.metcon.metconType) {
      case MetconType.amrap:
        return isRecord(
          metconSessionDescription.metconSession.rounds
              ?.mulNullable(MetconRecord.multiplier)
              ?.addNullable(metconSessionDescription.metconSession.reps),
          metconRecord.rounds
              ?.mulNullable(MetconRecord.multiplier)
              ?.addNullable(metconRecord.reps),
        );
      case MetconType.forTime:
        return metconRecord.time != null
            ? isRecord(
                metconSessionDescription.metconSession.time?.inMilliseconds,
                metconRecord.time?.inMilliseconds,
                minRecord: true,
              )
            : isRecord(
                metconSessionDescription.metconSession.rounds
                    ?.mulNullable(MetconRecord.multiplier)
                    ?.addNullable(metconSessionDescription.metconSession.reps),
                metconRecord.rounds
                    ?.mulNullable(MetconRecord.multiplier)
                    ?.addNullable(metconRecord.reps),
              );
      case MetconType.emom:
        return false;
    }
  }
}

class MetconRecord {
  MetconRecord({
    required this.time,
    required this.rounds,
    required this.reps,
  });

  factory MetconRecord.fromDbRecord(
    DbRecord r, {
    String prefix = '',
  }) {
    final time = r[prefix + Columns.time] as int?;
    final roundsAndReps = r[prefix + Columns.roundsAndReps] as int?;
    int? rounds;
    int? reps;
    if (roundsAndReps != null) {
      rounds = roundsAndReps ~/ multiplier;
      reps = roundsAndReps.remainder(multiplier);
    }
    return MetconRecord(
      time: time == null ? null : Duration(milliseconds: time),
      rounds: rounds,
      reps: reps,
    );
  }

  static const multiplier = 1000000;

  Duration? time;
  int? rounds;
  int? reps;
}
