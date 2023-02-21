import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioValueUnitDescriptionTable extends StatelessWidget {
  const CardioValueUnitDescriptionTable({
    required this.cardioSessionDescription,
    required this.currentDuration,
    this.showDatetimeCardioType = false,
    this.showCurrentElevation = false,
    super.key,
  });

  final CardioSessionDescription cardioSessionDescription;
  final Duration? currentDuration;
  final bool showDatetimeCardioType;
  final bool showCurrentElevation;

  static const _currentDurationOffset = Duration(minutes: 1);

  @override
  Widget build(BuildContext context) {
    final rowSpacer = TableRow(
      children: [
        Defaults.sizedBox.vertical.small,
        Defaults.sizedBox.vertical.small,
      ],
    );
    return Table(
      children: [
        if (showDatetimeCardioType) ...[
          TableRow(
            children: [
              ValueUnitDescription.datetime(
                cardioSessionDescription.cardioSession.datetime,
              ),
              ValueUnitDescription.cardioType(
                cardioSessionDescription.cardioSession.cardioType,
              ),
            ],
          ),
          rowSpacer,
        ],
        TableRow(
          children: [
            ValueUnitDescription.time(
              cardioSessionDescription.cardioSession.time,
            ),
            ValueUnitDescription.distance(
              cardioSessionDescription.cardioSession.distance,
            ),
          ],
        ),
        ...currentDuration != null
            ? [
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.speed(
                      cardioSessionDescription.cardioSession.speed,
                    ),
                    ValueUnitDescription.speed(
                      cardioSessionDescription.cardioSession.currentSpeed(
                        currentDuration! - _currentDurationOffset,
                        currentDuration!,
                      ),
                      current: true,
                    ),
                  ],
                ),
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.tempo(
                      cardioSessionDescription.cardioSession.tempo,
                    ),
                    ValueUnitDescription.tempo(
                      cardioSessionDescription.cardioSession.currentTempo(
                        currentDuration! - _currentDurationOffset,
                        currentDuration!,
                      ),
                      current: true,
                    ),
                  ],
                )
              ]
            : [
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.speed(
                      cardioSessionDescription.cardioSession.speed,
                    ),
                    ValueUnitDescription.tempo(
                      cardioSessionDescription.cardioSession.tempo,
                    ),
                  ],
                )
              ],
        rowSpacer,
        TableRow(
          children: [
            ValueUnitDescription.ascent(
              cardioSessionDescription.cardioSession.ascent,
            ),
            ValueUnitDescription.descent(
              cardioSessionDescription.cardioSession.descent,
            ),
          ],
        ),
        if (showCurrentElevation) ...[
          rowSpacer,
          TableRow(
            children: [
              ValueUnitDescription.elevation(
                cardioSessionDescription
                    .cardioSession.track?.lastOrNull?.elevation
                    .round(),
              ),
              Container()
            ],
          ),
        ],
        ...currentDuration != null
            ? [
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.avgCadence(
                      cardioSessionDescription.cardioSession.avgCadence,
                    ),
                    ValueUnitDescription.avgCadence(
                      cardioSessionDescription.cardioSession.currentCadence(
                        currentDuration! - _currentDurationOffset,
                        currentDuration!,
                      ),
                      current: true,
                    ),
                  ],
                ),
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.avgHeartRate(
                      cardioSessionDescription.cardioSession.avgHeartRate,
                    ),
                    ValueUnitDescription.avgHeartRate(
                      cardioSessionDescription.cardioSession.currentHeartRate(
                        currentDuration! - _currentDurationOffset,
                        currentDuration!,
                      ),
                      current: true,
                    ),
                  ],
                )
              ]
            : [
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.avgCadence(
                      cardioSessionDescription.cardioSession.avgCadence,
                    ),
                    ValueUnitDescription.avgHeartRate(
                      cardioSessionDescription.cardioSession.avgHeartRate,
                    ),
                  ],
                )
              ],
        //rowSpacer,
        //TableRow(
        //children: [
        //ValueUnitDescription.calories(
        //cardioSessionDescription.cardioSession.calories,
        //),
        //Container(),
        //],
        //),
      ],
    );
  }
}
