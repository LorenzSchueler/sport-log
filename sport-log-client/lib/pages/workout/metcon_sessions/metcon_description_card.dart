import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
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
                  for (var metconMovementDescription in metconDescription.moves)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(metconMovementDescription.movement.name),
                        ),
                        Text(metconMovementDescription.countUnitWeight),
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
