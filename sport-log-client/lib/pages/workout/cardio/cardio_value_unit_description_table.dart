import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioValueUnitDescriptionTable extends StatelessWidget {
  const CardioValueUnitDescriptionTable({
    required this.cardioSessionDescription,
    required this.currentDuration,
    Key? key,
  }) : super(key: key);

  final CardioSessionDescription cardioSessionDescription;
  final Duration? currentDuration;

  @override
  Widget build(BuildContext context) {
    TableRow rowSpacer = TableRow(
      children: [
        Defaults.sizedBox.vertical.normal,
        Defaults.sizedBox.vertical.normal,
      ],
    );
    return Table(
      children: [
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
                      cardioSessionDescription.cardioSession
                          .currentSpeed(currentDuration!),
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
                      cardioSessionDescription.cardioSession
                          .currentTempo(currentDuration!),
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
        ...currentDuration != null
            ? [
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription.avgCadence(
                      cardioSessionDescription.cardioSession.avgCadence,
                    ),
                    ValueUnitDescription.avgCadence(
                      cardioSessionDescription.cardioSession
                          .currentCadence(currentDuration!),
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
                      cardioSessionDescription.cardioSession
                          .currentHeartRate(currentDuration!),
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
