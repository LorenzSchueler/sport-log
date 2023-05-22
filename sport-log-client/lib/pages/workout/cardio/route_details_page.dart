import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/route.dart';
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
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(() => setState(() {}));

  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _touchLocationMarker =
      NullablePointer.nullPointer();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    await _dataProvider.deleteSingle(_route);
    if (mounted) {
      Navigator.pop(
        context,
        ReturnObject(
          action: ReturnAction.deleted,
          payload: _route,
        ), // needed for route details page
      );
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
            ),
            if (fullscreen.isOff)
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: "Stats", icon: Icon(AppIcons.numberedList)),
                  Tab(text: "Chart", icon: Icon(AppIcons.chart)),
                ],
              ),
            if (fullscreen.isOff && _tabController.index == 0)
              Container(
                padding: Defaults.edgeInsets.normal,
                color: Theme.of(context).colorScheme.background,
                child: RouteValueUnitDescriptionTable(route: _route),
              ),
            if (fullscreen.isOff && _tabController.index == 1)
              _route.track != null
                  ? Container(
                      color: const Color.fromARGB(150, 0, 0, 0),
                      child: DistanceChart(
                        chartLines: [_elevationLine()],
                        yFromZero: false,
                        touchCallback: _touchCallback,
                      ),
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
          ],
        ),
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
    if (mounted && file != null) {
      await showMessageDialog(
        context: context,
        text: 'Track exported to $file',
      );
    }
  }

  Future<void> _touchCallback(double? distance) async {
    final latLng = distance != null
        ? _route.track?.reversed
            .firstWhereOrNull((pos) => pos.distance <= distance)
            ?.latLng
        : null;

    await _mapController?.updateRouteMarker(_touchLocationMarker, latLng);
  }
}
