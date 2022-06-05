import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/extensions/num_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';

enum StrengthRecordType {
  maxWeight,
  maxCount,

  /// only if [Movement] has [MovementDimension.reps] and if [StrengthSet.count] >= 10
  maxEorm,
}

typedef StrengthRecords = Map<Int64, StrengthRecord>;

extension StrengthRecordExtension on StrengthRecords {
  List<StrengthRecordType> _getRecordTypesfromStats(
    StrengthSessionStats strengthSessionStats,
    StrengthRecord? strengthRecord,
  ) {
    List<StrengthRecordType> recordTypes = [];
    if (strengthRecord != null) {
      if (isRecord(strengthSessionStats.maxWeight, strengthRecord.maxWeight)) {
        recordTypes.add(StrengthRecordType.maxWeight);
      }
      if (strengthSessionStats.maxCount >= strengthRecord.maxCount) {
        recordTypes.add(StrengthRecordType.maxCount);
      }
      if (isRecord(strengthSessionStats.maxEorm, strengthRecord.maxEorm)) {
        recordTypes.add(StrengthRecordType.maxEorm);
      }
    }

    return recordTypes;
  }

  List<StrengthRecordType> getRecordTypes(
    StrengthSet strengthSet,
    Movement movement,
  ) {
    final strengthSessionStats =
        StrengthSessionStats.fromStrengthSets(DateTime.now(), [strengthSet]);
    final strengthRecord = this[movement.id];

    return _getRecordTypesfromStats(strengthSessionStats, strengthRecord);
  }

  List<StrengthRecordType> getCombinedRecordTypes(
    StrengthSessionDescription strengthSessionDescription,
  ) {
    final strengthSessionStats = StrengthSessionStats.fromStrengthSets(
      strengthSessionDescription.session.datetime,
      strengthSessionDescription.sets,
    );
    final strengthRecord = this[strengthSessionDescription.movement.id];

    return _getRecordTypesfromStats(strengthSessionStats, strengthRecord);
  }
}

class StrengthRecord {
  StrengthRecord({
    required this.maxWeight,
    required this.maxCount,
    required this.maxEorm,
  });

  factory StrengthRecord.fromDbRecord(
    DbRecord r, {
    String prefix = '',
  }) {
    return StrengthRecord(
      maxWeight: r[prefix + Columns.maxWeight] as double?,
      maxCount: r[prefix + Columns.maxCount]! as int,
      maxEorm: r[prefix + Columns.maxEorm] as double?,
    );
  }

  double? maxWeight;
  int maxCount;
  double? maxEorm;
}
