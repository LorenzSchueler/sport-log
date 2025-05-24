import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Position, Settings;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/route_planning_utils.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/cardio/route_value_unit_description_table.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/widgets/sync_status_button.dart';
import 'package:synchronized/synchronized.dart';

class RouteEditPage extends StatefulWidget {
  const RouteEditPage({required this.route, super.key});

  final Route? route;
  bool get isNew => route == null;

  @override
  State<RouteEditPage> createState() => _RouteEditPageState();
}

class _RouteEditPageState extends State<RouteEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = RouteDataProvider();
  final _lock = Lock();

  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();
  List<CircleAnnotation> _circles = [];
  List<PointAnnotation> _labels = [];

  SnapMode _snapMode = SnapMode.snapIfClose;

  bool _isSearching = false;

  MapController? _mapController;
  ElevationMapController? _elevationMapController;

  late final Route _route = (widget.route?.clone() ?? Route.defaultValue())
    ..track ??= []
    ..markedPositions ??= [];

  Future<void> _saveRoute() async {
    // clone because sanitation makes track and markedPositions null if empty
    final result = widget.isNew
        ? await _dataProvider.createSingle(_route.clone())
        : await _dataProvider.updateSingle(_route.clone());
    if (mounted) {
      if (result.isOk) {
        Navigator.pop(
          context,
          // needed for route details page
          ReturnObject.isNew(widget.isNew, _route),
        );
      } else {
        await showMessageDialog(
          context: context,
          title: "${widget.isNew ? 'Creating' : 'Updating'} Route Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _deleteRoute() async {
    final delete = await showDeleteWarningDialog(context, "Route");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result = await _dataProvider.deleteSingle(_route);
      if (mounted) {
        if (result.isOk) {
          Navigator.pop(
            context,
            // needed for route details page
            ReturnObject.deleted(_route),
          );
        } else {
          await showMessageDialog(
            context: context,
            title: "Deleting Route Failed",
            text: result.err.toString(),
          );
        }
      }
    }
    if (mounted) {
      Navigator.pop(
        context,
        // needed for route details page
        ReturnObject.deleted(_route),
      );
    }
  }

  Future<void> _updateLine({bool init = false}) async {
    if (init) {
      await _mapController?.updateRouteLine(_line, _route.track);
      return;
    }
    if (_route.markedPositions!.length >= 2) {
      if (mounted) {
        setState(() => _isSearching = true);
      }
      final track = await _lock.synchronized(
        () => RoutePlanningUtils.matchLocations(
          _route.markedPositions!,
          _snapMode,
          _elevationMapController?.getElevation,
        ),
      );
      if (mounted) {
        setState(() => _isSearching = false);
        if (track.isErr) {
          showSimpleToast(context, track.err.message);
        } else {
          setState(() {
            _route
              ..track = track.ok
              ..setDistance()
              ..setAscentDescent();
          });
          await _mapController?.updateRouteLine(_line, _route.track);
        }
      }
    } else if (mounted) {
      setState(() {
        _route
          ..track = []
          ..setDistance()
          ..setAscentDescent();
      });
      await _mapController?.updateRouteLine(_line, null);
    }
  }

  Future<void> _addPoint(LatLng latLng, int number) async {
    final label = await _mapController?.addLabel(latLng, "$number");
    if (label != null) {
      _labels.add(label);
    }
    final circle = await _mapController?.addRouteMarker(latLng);
    if (circle != null) {
      _circles.add(circle);
    }
  }

  Future<void> _updatePoints() async {
    await _mapController?.removeAllMarkers();
    _circles = [];
    await _mapController?.removeAllLabels();
    _labels = [];
    _route.markedPositions!.asMap().forEach((index, pos) {
      _addPoint(pos.latLng, index + 1);
    });
  }

  Future<void> _extendLine(LatLng location) async {
    final elevation = await _elevationMapController?.getElevation(location);
    if (mounted) {
      setState(() {
        _route.markedPositions!.add(
          Position(
            latitude: location.lat,
            longitude: location.lng,
            elevation: elevation ?? 0,
            distance: 0,
            time: Duration.zero,
          ),
        );
      });
    }
    await _addPoint(location, _route.markedPositions!.length);
    await _updateLine();
  }

  Future<void> _removePoint(int index) async {
    setState(() => _route.markedPositions!.removeAt(index));
    await _updatePoints();
    await _updateLine();
  }

  Future<void> _switchPoints(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex - 1) {
        final location = _route.markedPositions!.removeAt(oldIndex);
        if (newIndex - 1 == _route.markedPositions!.length) {
          _route.markedPositions!.add(location);
        } else {
          _route.markedPositions!.insert(newIndex - 1, location);
        }
      } else if (oldIndex > newIndex) {
        _route.markedPositions!.insert(
          newIndex,
          _route.markedPositions!.removeAt(oldIndex),
        );
      }
    });

    await _updatePoints();
    await _updateLine();
  }

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _mapController?.setBoundsFromTracks(
      _route.track,
      _route.markedPositions,
      padded: true,
    );
    await _updatePoints();
    await _updateLine(init: true);
  }

  void _onElevationMapCreated(ElevationMapController mapController) =>
      _elevationMapController = mapController;

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Route"),
          actions: [
            IconButton(
              onPressed: _deleteRoute,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed:
                  _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _route.isValidBeforeSanitation()
                  ? _saveRoute
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: ProviderConsumer(
          create: (_) => BoolToggle.on(),
          builder: (context, fullscreen, _) => Form(
            key: _formKey,
            child: Column(
              children: [
                if (fullscreen.isOff && Settings.instance.developerMode)
                  SyncStatusButton(
                    entity: _route,
                    dataProvider: RouteDataProvider(),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      MapboxMapWrapper(
                        showFullscreenButton: false,
                        showMapStylesButton: true,
                        showSelectRouteButton: false,
                        showSetNorthButton: true,
                        showCurrentLocationButton: false,
                        showCenterLocationButton: false,
                        showAddLocationButton: false,
                        onMapCreated: _onMapCreated,
                        onLongTap: _extendLine,
                      ),
                      if (_isSearching)
                        const Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: CircularProgressIndicator(
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IconButton(
                            onPressed: fullscreen.toggle,
                            iconSize: 50,
                            icon: Icon(
                              fullscreen.isOn
                                  ? AppIcons.arrowUp
                                  : AppIcons.arrowDown,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevationMap(onMapCreated: _onElevationMapCreated),
                if (fullscreen.isOff)
                  Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: Column(
                      children: [
                        SegmentedButton(
                          segments: SnapMode.values
                              .map(
                                (snapMode) => ButtonSegment(
                                  value: snapMode,
                                  label: Text(snapMode.name),
                                ),
                              )
                              .toList(),
                          selected: {_snapMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selected) {
                            setState(() => _snapMode = selected.first);
                            _updateLine();
                          },
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ReorderableListView.builder(
                            itemBuilder: (context, index) => ListTile(
                              key: ValueKey(index),
                              leading: IconButton(
                                onPressed: () => _removePoint(index),
                                icon: const Icon(AppIcons.delete),
                              ),
                              title: Text(
                                "${index + 1}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              trailing: const Icon(AppIcons.dragHandle),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.only(right: 10),
                            ),
                            itemCount: _route.markedPositions!.length,
                            onReorder: _switchPoints,
                            shrinkWrap: true,
                          ),
                        ),
                        const Divider(),
                        RouteValueUnitDescriptionTable(route: _route),
                        const Divider(),
                        TextFormField(
                          onChanged: (name) =>
                              setState(() => _route.name = name),
                          initialValue: _route.name,
                          validator: Validator.validateStringNotEmpty,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            icon: Icon(AppIcons.route),
                            labelText: "Name",
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
