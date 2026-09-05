import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  final cardioDataProvider = CardioSessionDataProvider();
  final routeDataProvider = RouteDataProvider();
  List<(CardioSession, CardioSession)>? updatedCardioSessions;
  List<(Route, Route)>? updatedRoutes;
  bool cardioSessionsWorking = false;
  bool routesWorking = false;

  Future<void> updateCardioElevationGainAndDistance() async {
    setState(() {
      cardioSessionsWorking = true;
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
        cardioSessionsWorking = false;
      });
    }
  }

  Future<void> updateRouteElevationGain() async {
    setState(() {
      routesWorking = true;
    });
    final routes = await routeDataProvider.getNonDeleted();

    // workaround to not capture routeDataProvider
    // see: https://api.dart.dev/dart-isolate/Isolate/run.html
    Future<List<(Route, Route)>> task(List<Route> routes) => Isolate.run(
      () => routes
          .where((r) => r.track != null)
          .sortedBy((r) => r.name)
          .map((old) => (old, old.clone()..setAscentDescent()))
          .toList(),
    );
    final updated = await task(routes);

    if (mounted) {
      setState(() {
        updatedRoutes = updated;
        routesWorking = false;
      });
    }
  }

  Future<void> applyCardioSessions() async {
    if (updatedCardioSessions != null) {
      setState(() {
        cardioSessionsWorking = true;
      });
      final result = await cardioDataProvider.updateMultiple(
        updatedCardioSessions!.map((c) => c.$2).toList(),
      );
      if (mounted) {
        setState(() {
          if (result.isOk) {
            updatedCardioSessions = null;
          }
          cardioSessionsWorking = false;
        });
        if (result.isErr) {
          await showMessageDialog(
            context: context,
            title: "Updating Cardio Sessions Failed",
            text: result.err.toString(),
          );
        }
      }
    }
  }

  Future<void> applyRoutes() async {
    if (updatedRoutes != null) {
      setState(() {
        routesWorking = true;
      });
      final result = await routeDataProvider.updateMultiple(
        updatedRoutes!.map((r) => r.$2).toList(),
      );
      if (mounted) {
        setState(() {
          if (result.isOk) {
            updatedRoutes = null;
          }
          routesWorking = false;
        });
        if (result.isErr) {
          await showMessageDialog(
            context: context,
            title: "Updating Routes Failed",
            text: result.err.toString(),
          );
        }
      }
    }
  }

  /// A row with [values] separated by spacer columns.
  ///
  /// The first value is left aligned, all others are right aligned.
  TableRow row(List<String> values) => TableRow(
    children: values
        .mapIndexed(
          (index, value) => [
            if (index > 0) Container(),
            Text(
              value,
              textAlign: index == 0 ? TextAlign.left : TextAlign.right,
            ),
          ],
        )
        .flattened
        .toList(),
  );

  Widget table(List<String> header, List<List<String>> rows) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          columnWidths: {
            for (var i = 1; i < 2 * header.length - 1; i += 2)
              i: const FixedColumnWidth(10),
          },
          children: [row(header), ...rows.map(row)],
        ),
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
            if (cardioSessionsWorking)
              Center(child: CircularProgressIndicator())
            else if (updatedCardioSessions == null)
              FilledButton(
                onPressed: updateCardioElevationGainAndDistance,
                child: const Text(
                  "Recompute Cardio Elevation Gain and Distance",
                  style: TextStyle(fontSize: 16),
                ),
              )
            else ...[
              table(
                [
                  "Date",
                  "Distance\nold",
                  "Distance\nnew",
                  "Ascent\nold",
                  "Ascent\nnew",
                  "Descent\nold",
                  "Descent\nnew",
                ],
                updatedCardioSessions!
                    .map(
                      (c) => [
                        c.$1.datetime.humanDateTime,
                        "${c.$1.distance}",
                        "${c.$2.distance}",
                        "${c.$1.ascent}",
                        "${c.$2.ascent}",
                        "${c.$1.descent}",
                        "${c.$2.descent}",
                      ],
                    )
                    .toList(),
              ),
              FilledButton(
                onPressed: applyCardioSessions,
                child: const Text("Apply"),
              ),
            ],
            const CaptionTile(caption: "Routes"),
            if (routesWorking)
              Center(child: CircularProgressIndicator())
            else if (updatedRoutes == null)
              FilledButton(
                onPressed: updateRouteElevationGain,
                child: const Text(
                  "Recompute Route Elevation Gain",
                  style: TextStyle(fontSize: 16),
                ),
              )
            else ...[
              table(
                [
                  "Name",
                  "Ascent\nold",
                  "Ascent\nnew",
                  "Descent\nold",
                  "Descent\nnew",
                ],
                updatedRoutes!
                    .map(
                      (r) => [
                        r.$1.name,
                        "${r.$1.ascent}",
                        "${r.$2.ascent}",
                        "${r.$1.descent}",
                        "${r.$2.descent}",
                      ],
                    )
                    .toList(),
              ),
              FilledButton(onPressed: applyRoutes, child: const Text("Apply")),
            ],
          ],
        ),
      ),
    );
  }
}
