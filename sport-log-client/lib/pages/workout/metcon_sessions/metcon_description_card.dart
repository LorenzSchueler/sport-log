import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';

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
              style: Theme.of(context).textTheme.headline5,
            ),
            TextTile(
              caption: "Type",
              child: Text(metconDescription.typeLengthDescription),
            ),
            TextTile(
              caption: "Movements",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var metconMovementDescription in metconDescription.moves)
                    Text(metconMovementDescription.movementText),
                ],
              ),
            ),
            if (metconDescription.metcon.description != null)
              TextTile(
                caption: "Description",
                child: Text(
                  metconDescription.metcon.description!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
