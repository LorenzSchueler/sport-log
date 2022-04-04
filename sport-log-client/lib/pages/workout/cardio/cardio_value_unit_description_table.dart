import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioValueUnitDescriptionTable extends StatelessWidget {
  final CardioSessionDescription cardioSessionDescription;
  const CardioValueUnitDescriptionTable({
    required this.cardioSessionDescription,
    Key? key,
  }) : super(key: key);

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
        ),
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
        ),
        rowSpacer,
        TableRow(
          children: [
            ValueUnitDescription.calories(
              cardioSessionDescription.cardioSession.calories,
            ),
            Container(),
          ],
        ),
      ],
    );
  }
}
