import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_records.dart';
import 'package:sport_log/widgets/app_icons.dart';

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
    return strengthRecord == null
        ? Container()
        : Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (strengthRecord!.maxWeight != null) ...[
                    const Icon(
                      AppIcons.medal,
                      color: Colors.orange,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.small,
                    Text(
                      "${strengthRecord!.maxWeight!.round()} kg",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ],
                  const Icon(
                    AppIcons.medal,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  Defaults.sizedBox.horizontal.small,
                  Text(
                    switch (movement.dimension) {
                      MovementDimension.reps =>
                        "${strengthRecord!.maxCount} reps",
                      MovementDimension.time =>
                        Duration(milliseconds: strengthRecord!.maxCount)
                            .formatMsMill,
                      MovementDimension.distance =>
                        '${strengthRecord!.maxCount} m',
                      MovementDimension.energy =>
                        '${strengthRecord!.maxCount} cal',
                    },
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (strengthRecord!.maxEorm != null) ...[
                    Defaults.sizedBox.horizontal.normal,
                    const Icon(
                      AppIcons.medal,
                      color: Colors.grey,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.small,
                    Text(
                      "${strengthRecord!.maxEorm!.round()} kg",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
          );
  }
}

class StrengthRecordMarkers extends StatelessWidget {
  const StrengthRecordMarkers({
    required this.strengthRecordTypes,
    super.key,
  });

  final List<StrengthRecordType> strengthRecordTypes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: strengthRecordTypes
          .map(
            (recordType) => switch (recordType) {
              StrengthRecordType.maxWeight => [
                  const Icon(
                    AppIcons.medal,
                    color: Colors.orange,
                    size: 20,
                  ),
                  Defaults.sizedBox.horizontal.normal,
                ],
              StrengthRecordType.maxCount => [
                  const Icon(
                    AppIcons.medal,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  Defaults.sizedBox.horizontal.normal,
                ],
              StrengthRecordType.maxEorm => [
                  const Icon(
                    AppIcons.medal,
                    color: Colors.grey,
                    size: 20,
                  ),
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
