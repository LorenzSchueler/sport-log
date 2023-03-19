import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/models/metcon/metcon_session_description.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class MetconSessionResultsCard extends StatelessWidget {
  const MetconSessionResultsCard({
    required this.metconSessionDescription,
    required this.metconSessionDescriptions,
    required this.metconRecords,
    super.key,
  });

  final MetconSessionDescription? metconSessionDescription;
  final List<MetconSessionDescription> metconSessionDescriptions;
  final MetconRecords metconRecords;

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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (metconSessionDescription != null)
              EditTile(
                leading: null,
                caption: "Score",
                child: Text(
                  "${metconSessionDescription!.shortResultDescription} (${metconSessionDescription!.metconSession.datetime.toHumanDate()})",
                ),
              ),
            if (metconSessionDescription?.metconSession.comments != null)
              EditTile(
                leading: null,
                caption: "Comments",
                child: Text(metconSessionDescription!.metconSession.comments!),
              ),
            EditTile(
              leading: null,
              caption: "Previous Scores",
              child: Column(
                children: [
                  for (final metconSessionDescription
                      in metconSessionDescriptions)
                    Row(
                      children: [
                        Text(
                          "${metconSessionDescription.shortResultDescription} (${metconSessionDescription.metconSession.datetime.toHumanDate()})",
                        ),
                        if (metconRecords
                            .isMetconRecord(metconSessionDescription)) ...[
                          Defaults.sizedBox.horizontal.normal,
                          const Icon(
                            AppIcons.medal,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ],
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
