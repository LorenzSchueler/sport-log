import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/pages/workout/cardio/route_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/charts/distance_chart.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

class RouteDetailsPage extends StatefulWidget {
  const RouteDetailsPage({required this.route, super.key});

  final Route route;

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  late Route _route;

  late MapboxMapController _mapController;
  Circle? _touchLocationMarker;

  @override
  void initState() {
    _route = widget.route.clone();
    super.initState();
  }

  void _setBoundsAndLine() {
    _mapController.setBoundsFromTracks(
      _route.track,
      null,
      padded: true,
    );
    if (_route.track != null) {
      _mapController.addRouteLine(_route.track!);
    }
  }

  Future<void> _pushEditPage() async {
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
        _setBoundsAndLine();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _pushEditPage,
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
                        onStyleLoadedCallback: _setBoundsAndLine,
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
                if (_route.track != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: const Color.fromARGB(120, 0, 0, 0),
                      child: DistanceChart(
                        chartLines: [_elevationLine()],
                        yFromZero: true,
                        touchCallback: _touchCallback,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: Defaults.edgeInsets.normal,
            color: Theme.of(context).colorScheme.background,
            child: RouteValueUnitDescriptionTable(
              route: _route,
            ),
          ),
        ],
      ),
    );
  }

  DistanceChartLine _elevationLine() =>
      DistanceChartLine.fromUngroupedChartValues(
        chartValues: _route.track
                ?.map(
                  (t) => DistanceChartValue(
                    distance: t.distance,
                    value: t.elevation,
                  ),
                )
                .toList() ??
            [],
        lineColor: Colors.white,
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

  Future<void> _touchCallback(Duration? y) async {
    final latLng = y != null
        ? _route.track?.reversed
            .firstWhereOrNull((pos) => pos.time <= y)
            ?.latLng
        : null;

    _touchLocationMarker =
        await _mapController.updateLocationMarker(_touchLocationMarker, latLng);
  }
}
