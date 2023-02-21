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
  List<StrengthRecordType> _getRecordTypesFromStats(
    StrengthSessionStats strengthSessionStats,
    StrengthRecord? strengthRecord,
  ) =>
      [
        if (isRecord(strengthSessionStats.maxWeight, strengthRecord?.maxWeight))
          StrengthRecordType.maxWeight,
        if (isRecord(strengthSessionStats.maxCount, strengthRecord?.maxCount))
          StrengthRecordType.maxCount,
        if (isRecord(strengthSessionStats.maxEorm, strengthRecord?.maxEorm))
          StrengthRecordType.maxEorm
      ];

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

    return _getRecordTypesFromStats(strengthSessionStats, strengthRecord);
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

    return _getRecordTypesFromStats(strengthSessionStats, strengthRecord);
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

  @override
  String toString() =>
      "{maxWeight: $maxWeight, maxCount: $maxCount, maxEorm: $maxEorm}";
}
