import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/search.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/pages/workout/cardio/no_track.dart';
import 'package:sport_log/pages/workout/cardio/route_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/charts/distance_chart.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class RouteDetailsPage extends StatefulWidget {
  const RouteDetailsPage({required this.route, super.key});

  final Route route;

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage>
    with SingleTickerProviderStateMixin {
  final _dataProvider = RouteDataProvider();

  late Route _route = widget.route.clone();

  MapController? _mapController;

  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _touchLocationMarker =
      NullablePointer.nullPointer();

  late DistanceChartLine _elevationLine = _getElevationLine();
  DistanceChartLine _getElevationLine() =>
      DistanceChartLine.fromValues<Position>(
        values: _route.track,
        getDistance: (p) => p.distance,
        getValue: (p) => p.elevation,
        lineColor: _elevationColor,
        absolute: false,
      );

  int? _distance;
  int? _elevation;

  static const _distanceColor = Colors.white;
  static const _elevationColor = Color.fromARGB(255, 170, 130, 100);

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _setBoundsAndLine();
  }

  Future<void> _setBoundsAndLine() async {
    await _mapController?.setBoundsFromTracks(
      _route.track,
      _route.markedPositions,
      padded: true,
    );
    await _mapController?.updateRouteLine(_routeLine, _route.track);
    await _mapController?.removeAllMarkers();
    await _mapController?.removeAllLabels();
    if (_route.markedPositions != null) {
      for (var i = 0; i < _route.markedPositions!.length; i++) {
        final latLng = _route.markedPositions![i].latLng;
        await _mapController?.addRouteMarker(latLng);
        await _mapController?.addLabel(latLng, "${i + 1}");
      }
    }
  }

  Future<void> _deleteRoute() async {
    final delete = await showDeleteWarningDialog(context, "Route");
    if (!delete) {
      return;
    }
    final result = await _dataProvider.deleteSingle(_route);
    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(context);
      } else {
        await showMessageDialog(
          context: context,
          text: "Deleting Route failed:\n${result.failure}",
        );
      }
    }
  }

  Future<void> _pushEditPage() async {
    final returnObj = await Navigator.pushNamed(
      context,
      Routes.routeEdit,
      arguments: _route,
    );
    if (returnObj is ReturnObject<Route> && mounted) {
      if (returnObj.action == ReturnAction.deleted) {
        Navigator.pop(context);
      } else {
        setState(() {
          _route = returnObj.payload;
          _elevationLine = _getElevationLine();
        });
        await _setBoundsAndLine();
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
            onPressed: _deleteRoute,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _pushEditPage,
            icon: const Icon(AppIcons.edit),
          )
        ],
      ),
      body: ProviderConsumer(
        create: (_) => BoolToggle.off(),
        builder: (context, fullscreen, _) => Column(
          children: [
            Expanded(
              child: _route.track != null && _route.track!.isNotEmpty
                  ? MapboxMapWrapper(
                      showFullscreenButton: true,
                      showMapStylesButton: true,
                      showSelectRouteButton: false,
                      showSetNorthButton: true,
                      showCurrentLocationButton: false,
                      showCenterLocationButton: false,
                      onFullscreenToggle: fullscreen.setState,
                      scaleAtTop: fullscreen.isOff,
                      onMapCreated: _onMapCreated,
                    )
                  : const NoTrackPlaceholder(),
            ),
            if (fullscreen.isOff) ...[
              Padding(
                padding: Defaults.edgeInsets.normal,
                child: RouteValueUnitDescriptionTable(route: _route),
              ),
              if (_route.track != null) ...[
                const Divider(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_distance != null)
                      Text(
                        "${(_distance! / 1000).toStringAsFixed(3)} km",
                        style: const TextStyle(color: _distanceColor),
                      ),
                    if (_elevation != null)
                      Text(
                        "$_elevation m",
                        style: const TextStyle(color: _elevationColor),
                      ),
                    // placeholder when no value is set
                    if (_distance == null && _elevation == null) const Text("")
                  ],
                ),
                SizedBox(
                  height: 250,
                  child: DistanceChart(
                    chartLines: [_elevationLine],
                    touchCallback: _touchCallback,
                  ),
                )
              ]
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _exportFile() async {
    final file = await saveTrackAsGpx(_route.track ?? []);
    if (mounted && file != null) {
      await showMessageDialog(
        context: context,
        text: 'Track exported to $file',
      );
    }
  }

  Future<void> _touchCallback(double? distance) async {
    final chartIndex = distance != null
        ? binarySearchClosest(
            _elevationLine.chartValues,
            (value) => value.distance,
            distance,
          )
        : null;
    final chartValue =
        chartIndex != null ? _elevationLine.chartValues[chartIndex] : null;

    setState(() {
      _distance = chartValue?.distance.round();
      _elevation = chartValue?.value.round();
    });

    final positionIndex = distance != null && _route.track != null
        ? binarySearchClosest(
            _route.track!,
            (pos) => pos.distance,
            distance,
          )
        : null;
    final position =
        positionIndex != null ? _route.track![positionIndex] : null;

    await _mapController?.updateRouteMarker(
      _touchLocationMarker,
      position?.latLng,
    );
  }
}
