import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/pages/workout/charts/duration_chart.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RouteDetailsPage extends StatefulWidget {
  const RouteDetailsPage({required this.route, super.key});

  final Route route;

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  late Route _route;

  late MapboxMapController _mapController;
  List<double>? currentChartXValues;
  List<double>? currentChartYValues;

  @override
  void initState() {
    _route = widget.route.clone();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TableRow rowSpacer = TableRow(
      children: [
        Defaults.sizedBox.vertical.normal,
        Defaults.sizedBox.vertical.normal,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_route.name),
        actions: [
          if (_route.track != null && _route.track!.isNotEmpty)
            IconButton(
              onPressed: _exportFile,
              icon: const Icon(AppIcons.download),
            ),
          IconButton(
            onPressed: () async {
              final returnObj = await Navigator.pushNamed(
                context,
                Routes.cardio.routeEdit,
                arguments: _route,
              );
              if (returnObj is ReturnObject<Route> && mounted) {
                if (returnObj.action == ReturnAction.deleted) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _route = returnObj.payload;
                  });
                }
              }
            },
            icon: const Icon(AppIcons.edit),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _route.track != null
                    ? MapboxMap(
                        accessToken: Config.instance.accessToken,
                        styleString: MapboxStyles.OUTDOORS,
                        initialCameraPosition:
                            context.read<Settings>().lastMapPosition,
                        onMapCreated: (MapboxMapController controller) =>
                            _mapController = controller,
                        onStyleLoadedCallback: () {
                          _mapController.setBoundsFromTracks(
                            _route.track,
                            null,
                            padded: true,
                          );
                          if (_route.track != null) {
                            _mapController.addRouteLine(_route.track!);
                          }
                        },
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.route,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            Defaults.sizedBox.horizontal.normal,
                            const Text("no track available"),
                          ],
                        ),
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: currentChartYValues
                                ?.map((e) => Text(e.toString()))
                                .toList() ??
                            [],
                      ),
                      DurationChart(
                        chartLines: [_elevationLine()],
                        yFromZero: true,
                        rightYScaleFactor: 5,
                        touchCallback: (xValues, yValues) {
                          setState(() {
                            currentChartXValues = xValues;
                            currentChartYValues = yValues;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: Defaults.edgeInsets.normal,
            color: Theme.of(context).colorScheme.background,
            child: Column(
              children: [
                // TODO remove
                if (_route.track != null && _route.track!.isNotEmpty)
                  IconButton(
                    onPressed: _exportFile,
                    icon: const Icon(AppIcons.download),
                  ),
                Table(
                  children: [
                    TableRow(
                      children: [
                        ValueUnitDescription.distance(_route.distance),
                        ValueUnitDescription.name(_route.name)
                      ],
                    ),
                    rowSpacer,
                    TableRow(
                      children: [
                        ValueUnitDescription.ascent(_route.ascent),
                        ValueUnitDescription.descent(_route.descent),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DurationChartLine _elevationLine() =>
      DurationChartLine.fromUngroupedChartValues(
        chartValues: _route.track
                ?.map(
                  (t) => DurationChartValue(
                    duration: t.time,
                    value: t.elevation,
                  ),
                )
                .toList() ??
            [],
        lineColor: Colors.white,
        isRight: true,
      );

  Future<void> _exportFile() async {
    final file = await saveTrackAsGpx(_route.track ?? []);
    if (file != null) {
      await showMessageDialog(
        context: context,
        text: 'Track exported to $file',
      );
    }
  }
}
