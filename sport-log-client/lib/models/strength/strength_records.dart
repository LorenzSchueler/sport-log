import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/extensions/num_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/eorm.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';

enum StrengthRecordType {
  maxWeight,

  /// best count, i.e. the smallest one for [MovementDimension.time]
  maxCount,

  /// only if [Movement] has [MovementDimension.reps] and if [StrengthSet.count] <= [eormMaxRepCount]
  maxEorm,
}

typedef StrengthRecords = Map<Int64, StrengthRecord>;

extension StrengthRecordExtension on StrengthRecords {
  List<StrengthRecordType> _getRecordTypesFromStats(
    StrengthSessionStats strengthSessionStats,
    StrengthRecord? strengthRecord,
    MovementDimension movementDimension,
  ) {
    // for time the smallest count is the best one
    final minRecord = movementDimension == MovementDimension.time;
    return [
      if (isRecord(strengthSessionStats.maxWeight, strengthRecord?.maxWeight))
        StrengthRecordType.maxWeight,
      if (isRecord(
        minRecord
            ? strengthSessionStats.minCount
            : strengthSessionStats.maxCount,
        strengthRecord?.maxCount,
        minRecord: minRecord,
      ))
        StrengthRecordType.maxCount,
      if (isRecord(strengthSessionStats.maxEorm, strengthRecord?.maxEorm))
        StrengthRecordType.maxEorm,
    ];
  }

  List<StrengthRecordType> getRecordTypes(
    StrengthSet strengthSet,
    Movement movement,
  ) {
    final strengthSessionStats = StrengthSessionStats.fromStrengthSets(
      DateTime.now(),
      movement.dimension,
      [strengthSet],
    );
    final strengthRecord = this[movement.id];

    return _getRecordTypesFromStats(
      strengthSessionStats,
      strengthRecord,
      movement.dimension,
    );
  }

  List<StrengthRecordType> getCombinedRecordTypes(
    StrengthSessionDescription strengthSessionDescription,
  ) {
    final strengthSessionStats = StrengthSessionStats.fromStrengthSets(
      strengthSessionDescription.session.datetime,
      strengthSessionDescription.movement.dimension,
      strengthSessionDescription.sets,
    );
    final strengthRecord = this[strengthSessionDescription.movement.id];

    return _getRecordTypesFromStats(
      strengthSessionStats,
      strengthRecord,
      strengthSessionDescription.movement.dimension,
    );
  }
}

class StrengthRecord {
  StrengthRecord({
    required this.maxWeight,
    required this.maxCount,
    required this.maxEorm,
    required this.maxWeightForReps,
  });

  factory StrengthRecord.fromDbRecord(DbRecord r, {String prefix = ''}) {
    return StrengthRecord(
      maxWeight: r[prefix + Columns.maxWeight] as double?,
      maxCount: r[prefix + Columns.maxCount]! as int,
      maxEorm: r[prefix + Columns.maxEorm] as double?,
      maxWeightForReps: {
        for (var reps = 1; reps <= eormMaxRepCount; reps++)
          if (r[prefix + Columns.maxWeightForReps(reps)] != null)
            reps: r[prefix + Columns.maxWeightForReps(reps)]! as double,
      },
    );
  }

  double? maxWeight;

  /// best count, which is the smallest one for [MovementDimension.time]
  int maxCount;
  double? maxEorm;

  /// max weight per rep count; only for [Movement]s with [MovementDimension.reps]
  Map<int, double> maxWeightForReps;

  @override
  String toString() =>
      "{maxWeight: $maxWeight, maxCount: $maxCount, maxEorm: $maxEorm, maxWeightForReps: $maxWeightForReps}";
}
