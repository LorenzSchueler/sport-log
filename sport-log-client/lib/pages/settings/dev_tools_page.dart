import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  final cardioDataProvider = CardioSessionDataProvider();
  List<(CardioSession, CardioSession)>? updatedCardioSessions;
  bool working = false;

  Future<void> updateCardioElevationGainAndDistance() async {
    setState(() {
      working = true;
    });
    final cardioSessions = await cardioDataProvider.getNonDeleted();

    // workaround to not capture cardioDataProvider
    // see: https://api.dart.dev/dart-isolate/Isolate/run.html
    Future<List<(CardioSession, CardioSession)>> task(
      List<CardioSession> cardioSessions,
    ) => Isolate.run(
      () => cardioSessions
          .where((c) => c.track != null)
          .sortedBy((c) => c.datetime)
          .map((old) {
            final updated = old.clone()
              ..applyDistanceThresholdFilter()
              ..setAscentDescent();
            return (old, updated);
          })
          .toList(),
    );
    final updated = await task(cardioSessions);

    if (mounted) {
      setState(() {
        updatedCardioSessions = updated;
        working = false;
      });
    }
  }

  Future<void> apply() async {
    if (updatedCardioSessions != null) {
      setState(() {
        working = true;
      });
      await cardioDataProvider.updateMultiple(
        updatedCardioSessions!.map((c) => c.$2).toList(),
      );
      if (mounted) {
        setState(() {
          updatedCardioSessions = null;
          working = false;
        });
      }
    }
  }

  TableRow row(
    String value1,
    String value2,
    String value3,
    String value4,
    String value5,
    String value6,
    String value7,
  ) => TableRow(
    children: [
      Text(value1),
      Container(),
      Text(value2, textAlign: TextAlign.right),
      Container(),
      Text(value3, textAlign: TextAlign.right),
      Container(),
      Text(value4, textAlign: TextAlign.right),
      Container(),
      Text(value5, textAlign: TextAlign.right),
      Container(),
      Text(value6, textAlign: TextAlign.right),
      Container(),
      Text(value7, textAlign: TextAlign.right),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dev Tools")),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView(
          children: [
            const CaptionTile(caption: "Cardio Sessions"),
            if (working) Center(child: CircularProgressIndicator()),
            if (!working && updatedCardioSessions == null)
              FilledButton(
                onPressed: updateCardioElevationGainAndDistance,
                child: const Text(
                  "Recompute Cardio Elevation Gain and Distance",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            if (!working && updatedCardioSessions != null) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  columnWidths: const {
                    1: FixedColumnWidth(10),
                    3: FixedColumnWidth(10),
                    5: FixedColumnWidth(10),
                    7: FixedColumnWidth(10),
                    9: FixedColumnWidth(10),
                    11: FixedColumnWidth(10),
                  },
                  children:
                      updatedCardioSessions!
                          .map(
                            (c) => row(
                              c.$1.datetime.humanDateTime,
                              "${c.$1.distance}",
                              "${c.$2.distance}",
                              "${c.$1.ascent}",
                              "${c.$2.ascent}",
                              "${c.$1.descent}",
                              "${c.$2.descent}",
                            ),
                          )
                          .toList()
                        ..insert(
                          0,
                          row(
                            "Date",
                            "Distance\nold",
                            "Distance\nnew",
                            "Ascent\nold",
                            "Ascent\nnew",
                            "Descent\nold",
                            "Descent\nnew",
                          ),
                        ),
                ),
              ),
              FilledButton(onPressed: apply, child: const Text("Apply")),
            ],
          ],
        ),
      ),
    );
  }
}
