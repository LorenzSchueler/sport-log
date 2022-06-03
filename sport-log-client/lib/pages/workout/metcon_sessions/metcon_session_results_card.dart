import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/metcon/metcon_session_description.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';

class MetconSessionResultsCard extends StatelessWidget {
  const MetconSessionResultsCard({
    required this.metconSessionDescription,
    required this.metconSessionDescriptions,
    Key? key,
  }) : super(key: key);

  final MetconSessionDescription? metconSessionDescription;
  final List<MetconSessionDescription> metconSessionDescriptions;

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
              "Results",
              style: Theme.of(context).textTheme.headline5,
            ),
            if (metconSessionDescription != null)
              TextTile(
                caption: "Score",
                child: Text(
                  "${metconSessionDescription!.shortResultDescription} (${metconSessionDescription!.metconSession.datetime.toHumanDate()})",
                ),
              ),
            if (metconSessionDescription?.metconSession.comments != null)
              TextTile(
                caption: "Comments",
                child: Text(metconSessionDescription!.metconSession.comments!),
              ),
            TextTile(
              caption: "Previous Scores",
              child: Column(
                children: [
                  for (final metconSessionDescription
                      in metconSessionDescriptions)
                    Text(
                      "${metconSessionDescription.shortResultDescription} (${metconSessionDescription.metconSession.datetime.toHumanDate()})",
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
