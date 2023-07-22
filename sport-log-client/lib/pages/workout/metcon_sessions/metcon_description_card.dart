import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class MetconDescriptionCard extends StatelessWidget {
  const MetconDescriptionCard({required this.metconDescription, super.key});

  final MetconDescription metconDescription;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Metcon",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            EditTile(
              leading: null,
              caption: "Type",
              child: Text(metconDescription.typeLengthDescription),
            ),
            EditTile(
              leading: null,
              caption: "Movements",
              unboundedHeight: true,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  for (var mmd in metconDescription.moves)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(mmd.movement.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            switch (mmd.movement.dimension) {
                              MovementDimension.distance =>
                                "${mmd.metconMovement.count} ${mmd.metconMovement.distanceUnit!.name}",
                              MovementDimension.time =>
                                Duration(milliseconds: mmd.metconMovement.count)
                                    .formatTimeShort,
                              _ =>
                                "${mmd.metconMovement.count} ${mmd.movement.dimension.name}",
                            },
                          ),
                        ),
                        Text(
                          mmd.metconMovement.maleWeight != null &&
                                  mmd.metconMovement.femaleWeight != null
                              ? "@ ${formatWeight(mmd.metconMovement.maleWeight!, mmd.metconMovement.femaleWeight)}"
                              : "",
                        )
                      ],
                    )
                ],
              ),
            ),
            if (metconDescription.metcon.description != null)
              EditTile(
                leading: null,
                caption: "Description",
                child: Text(metconDescription.metcon.description!),
              ),
          ],
        ),
      ),
    );
  }
}
