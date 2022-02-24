import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';

class MetconSessionDetailsPage extends StatefulWidget {
  final MetconSessionDescription metconSessionDescription;

  const MetconSessionDetailsPage({
    Key? key,
    required this.metconSessionDescription,
  }) : super(key: key);

  @override
  State<MetconSessionDetailsPage> createState() =>
      MetconSessionDetailsPageState();
}

class MetconSessionDetailsPageState extends State<MetconSessionDetailsPage> {
  final _logger = Logger('MetconSessionDetailsPage');

  String movementText(MetconMovementDescription metconSessionDescription) {
    String text =
        "${metconSessionDescription.movement.name} ${metconSessionDescription.metconMovement.count} ";
    text += metconSessionDescription.movement.dimension ==
            MovementDimension.distance
        ? metconSessionDescription.metconMovement.distanceUnit!.displayName
        : metconSessionDescription.movement.dimension.displayName;
    if (metconSessionDescription.metconMovement.weight != null) {
      text += " @ ${metconSessionDescription.metconMovement.weight} kg";
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    MetconSessionDescription metconSessionDescription =
        widget.metconSessionDescription;

    return Scaffold(
      appBar: AppBar(
        title: Text(metconSessionDescription.metconDescription.name),
        actions: [
          IconButton(
            onPressed: () async {
              final returnObj = await Navigator.pushNamed(
                context,
                Routes.metcon.sessionEdit,
                arguments: metconSessionDescription,
              );
              if (returnObj is ReturnObject<MetconSessionDescription>) {
                setState(() {
                  metconSessionDescription = returnObj.payload;
                });
              }
            },
            icon: const Icon(AppIcons.edit),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            const Text(
              "Metcon",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            TextTile(
              caption: "Type",
              child: Text(metconSessionDescription.typeLengthDescription),
            ),
            TextTile(
              caption: "Movements",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var metconMovementDescription
                      in metconSessionDescription.metconDescription.moves)
                    Text(movementText(metconMovementDescription)),
                ],
              ),
            ),
            if (metconSessionDescription.metconDescription.metcon.description !=
                null)
              TextTile(
                caption: "Description",
                child: Text(
                  metconSessionDescription
                      .metconDescription.metcon.description!,
                ),
              ),
            Defaults.sizedBox.vertical.big,
            const Text(
              "Results",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            TextTile(
              caption: "Score",
              child: Text(
                "${metconSessionDescription.shortResultDescription} (${formatDate(metconSessionDescription.metconSession.datetime)})",
              ),
            ),
            const TextTile(
              caption: "Best Score",
              child: Text("<my best score> <date>"),
            ),
            if (metconSessionDescription.metconSession.comments != null)
              TextTile(
                caption: "Comments",
                child: Text(metconSessionDescription.metconSession.comments!),
              ),
          ],
        ),
      ),
    );
  }
}
