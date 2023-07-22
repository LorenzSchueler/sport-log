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
            if (metconSessionDescription != null)
              EditTile(
                leading: null,
                caption: "Date",
                child: Text(
                  metconSessionDescription!.metconSession.datetime
                      .toHumanDate(),
                ),
              ),
            if (metconSessionDescription != null)
              EditTile(
                leading: null,
                caption: "Score",
                child: Text(
                  "${metconSessionDescription!.shortResultDescription} ${metconSessionDescription!.metconSession.rx ? "Rx" : "Scaled"}",
                ),
              ),
            if (metconSessionDescription?.metconSession.comments != null)
              EditTile(
                leading: null,
                caption: "Comments",
                unboundedHeight: true,
                child: Text(metconSessionDescription!.metconSession.comments!),
              ),
            EditTile(
              leading: null,
              caption: "All Scores",
              unboundedHeight: true,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  for (final msd in metconSessionDescriptions)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(msd.shortResultDescription),
                        ),
                        msd.metconSession.rx
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Rx"),
                                  Defaults.sizedBox.horizontal.normal,
                                  if (metconRecords.isMetconRecord(msd))
                                    const Icon(
                                      AppIcons.medal,
                                      color: Colors.orange,
                                      size: 20,
                                    )
                                ],
                              )
                            : const Text("Scaled"),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(msd.metconSession.datetime.toHumanDate()),
                        )
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
