import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/eorm.dart';
import 'package:sport_log/models/strength/strength_records.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class StrengthRecordsCard extends StatelessWidget {
  StrengthRecordsCard({
    required this.movement,
    required StrengthRecords strengthRecords,
    super.key,
  }) : strengthRecord = strengthRecords[movement.id];

  final Movement movement;
  final StrengthRecord? strengthRecord;

  @override
  Widget build(BuildContext context) {
    if (strengthRecord == null) {
      return Container();
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecordMedalsRow(
              movement: movement,
              strengthRecord: strengthRecord!,
            ),
            if (strengthRecord!.maxWeightForReps.isNotEmpty) ...[
              Defaults.sizedBox.vertical.normal,
              _MaxWeightForRepsTile(
                maxWeightForReps: strengthRecord!.maxWeightForReps,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordMedalsRow extends StatelessWidget {
  const _RecordMedalsRow({
    required this.movement,
    required this.strengthRecord,
  });

  final Movement movement;
  final StrengthRecord strengthRecord;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (strengthRecord.maxWeight != null) ...[
          const Icon(AppIcons.medal, color: Colors.orange, size: 20),
          Defaults.sizedBox.horizontal.small,
          Text(
            "${strengthRecord.maxWeight!.round()} kg",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Defaults.sizedBox.horizontal.normal,
        ],
        const Icon(AppIcons.medal, color: Colors.yellow, size: 20),
        Defaults.sizedBox.horizontal.small,
        Text(switch (movement.dimension) {
          MovementDimension.reps => "${strengthRecord.maxCount} reps",
          MovementDimension.time => Duration(
            milliseconds: strengthRecord.maxCount,
          ).formatMsMill,
          MovementDimension.distance => '${strengthRecord.maxCount} m',
          MovementDimension.energy => '${strengthRecord.maxCount} cal',
        }, style: Theme.of(context).textTheme.bodyLarge),
        if (strengthRecord.maxEorm != null) ...[
          Defaults.sizedBox.horizontal.normal,
          const Icon(AppIcons.medal, color: Colors.grey, size: 20),
          Defaults.sizedBox.horizontal.small,
          Text(
            "${strengthRecord.maxEorm!.round()} kg",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}

class _MaxWeightForRepsTile extends StatelessWidget {
  const _MaxWeightForRepsTile({required this.maxWeightForReps});

  final Map<int, double> maxWeightForReps;

  @override
  Widget build(BuildContext context) {
    return EditTile(
      leading: null,
      caption: "Max Weight per Reps",
      unboundedHeight: true,
      bigText: false,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          for (var reps = 1; reps <= eormMaxRepCount; reps++)
            if (maxWeightForReps[reps] case final weight?)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text("$reps reps"),
                  ),
                  Text(formatWeight(weight)),
                ],
              ),
        ],
      ),
    );
  }
}

class StrengthRecordMarkers extends StatelessWidget {
  const StrengthRecordMarkers({required this.strengthRecordTypes, super.key});

  final List<StrengthRecordType> strengthRecordTypes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: strengthRecordTypes
          .map(
            (recordType) => switch (recordType) {
              StrengthRecordType.maxWeight => [
                const Icon(AppIcons.medal, color: Colors.orange, size: 20),
                Defaults.sizedBox.horizontal.normal,
              ],
              StrengthRecordType.maxCount => [
                const Icon(AppIcons.medal, color: Colors.yellow, size: 20),
                Defaults.sizedBox.horizontal.normal,
              ],
              StrengthRecordType.maxEorm => [
                const Icon(AppIcons.medal, color: Colors.grey, size: 20),
                Defaults.sizedBox.horizontal.normal,
              ],
            },
          )
          .toList()
          .flattened
          .toList(),
    );
  }
}
