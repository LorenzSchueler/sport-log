import 'dart:io';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/cardio/route_value_unit_description_table.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class RouteEditPage extends StatefulWidget {
  const RouteEditPage({required this.route, super.key});

  final Route? route;

  @override
  State<RouteEditPage> createState() => _RouteEditPageState();
}

class _RouteEditPageState extends State<RouteEditPage> {
  final _logger = Logger('RouteEditPage');
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = RouteDataProvider();

  Line? _line;
  List<Circle> _circles = [];
  List<Symbol> _symbols = [];

  bool _listExpanded = false;

  late MapboxMapController _mapController;

  late final Route _route;

  @override
  void initState() {
    _route = widget.route?.clone() ?? Route.defaultValue();
    _route.track ??= [];
    _route.markedPositions ??= [];
    super.initState();
  }

  Future<void> _saveRoute() async {
    _logger.i("saving route");
    final result = widget.route != null
        ? await _dataProvider.updateSingle(_route)
        : await _dataProvider.createSingle(_route);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      if (mounted) {
        Navigator.pop(
          context,
          ReturnObject(
            action: widget.route == null
                ? ReturnAction.created
                : ReturnAction.updated,
            payload: _route,
          ), // needed for route details page
        );
      }
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Route Entry failed:\n${result.failure}',
      );
    }
  }

  Future<void> _deleteRoute() async {
    if (widget.route != null) {
      await _dataProvider.deleteSingle(_route);
    }
    _formKey.currentState!.deactivate();
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

  Future<void> _matchLocations() async {
    DirectionsApiResponse response;
    try {
      response = await Defaults.mapboxApi.directions.request(
        profile: NavigationProfile.WALKING,
        geometries: NavigationGeometries.POLYLINE,
        coordinates: _route.markedPositions!
            .map((e) => [e.latitude, e.longitude])
            .toList(),
      );
    } on SocketException {
      showSimpleToast(context, 'No Internet connection.');
      return;
    }
    if (response.error != null) {
      if (response.error is NavigationNoRouteError) {
        _logger.i(response.error);
      } else if (response.error is NavigationNoSegmentError) {
        _logger.i(response.error);
      } else {
        _logger.i(response.error.runtimeType);
      }
    } else if (response.routes != null && response.routes!.isNotEmpty) {
      NavigationRoute navRoute = response.routes![0];
      List<Position> track = [];
      for (final pointLatLng
          in PolylinePoints().decodePolyline(navRoute.geometry as String)) {
        track.add(
          Position(
            latitude: pointLatLng.latitude,
            longitude: pointLatLng.longitude,
            elevation: 0, // TODO
            distance: track.isEmpty
                ? 0
                : track.last
                    .addDistanceTo(pointLatLng.latitude, pointLatLng.longitude),
            time: Duration.zero,
          ),
        );
      }
      _logger
        ..i("mapbox distance ${navRoute.distance}")
        ..i("own distance ${track.last.distance}");
      setState(() {
        _route
          ..track = track
          ..setDistance()
          ..setAscentDescent();
      });
    }
  }

  Future<void> _updateLine() async {
    await _matchLocations();
    await _mapController.updateRouteLine(_line, _route.track);
  }

  Future<void> _addPoint(LatLng latLng, int number) async {
    _symbols.add(
      await _mapController.addSymbol(
        SymbolOptions(
          textField: "$number",
          textOffset: const Offset(0, 1),
          geometry: latLng,
        ),
      ),
    );
    _circles.add(await _mapController.addLocationMarker(latLng));
  }

  Future<void> _updatePoints() async {
    await _mapController.removeCircles(_circles);
    _circles = [];
    await _mapController.removeSymbols(_symbols);
    _symbols = [];
    _route.markedPositions!.asMap().forEach((index, pos) {
      _addPoint(pos.latLng, index + 1);
    });
  }

  Future<void> _extendLine(LatLng location) async {
    if (_route.markedPositions!.length == 25) {
      await showMessageDialog(
        context: context,
        title: "Point maximum reached",
        text: "You can only set 25 points.",
      );
      return;
    }
    setState(() {
      _route.markedPositions!.add(
        Position(
          latitude: location.latitude,
          longitude: location.longitude,
          elevation: 0, // TODO
          distance: 0,
          time: Duration.zero,
        ),
      );
    });
    await _addPoint(location, _route.markedPositions!.length);
    await _updateLine();
  }

  Future<void> _removePoint(int index) async {
    setState(() {
      _route.markedPositions!.removeAt(index);
    });
    await _updatePoints();
    await _updateLine();
  }

  Future<void> _switchPoints(int oldIndex, int newIndex) async {
    setState(() {
      _logger.i("old: $oldIndex, new: $newIndex");
      if (oldIndex < newIndex - 1) {
        Position location = _route.markedPositions!.removeAt(oldIndex);
        if (newIndex - 1 == _route.markedPositions!.length) {
          _route.markedPositions!.add(location);
        } else {
          _route.markedPositions!.insert(newIndex - 1, location);
        }
      } else if (oldIndex > newIndex) {
        _route.markedPositions!
            .insert(newIndex, _route.markedPositions!.removeAt(oldIndex));
      }
    });

    await _updatePoints();
    await _updateLine();
  }

  Widget _buildExpandableListContainer() {
    return _listExpanded
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _listExpanded = false;
                  }),
                  child: const Text("hide List"),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ReorderableListView.builder(
                  itemBuilder: (context, index) => ListTile(
                    key: ValueKey(index),
                    leading: IconButton(
                      onPressed: () => _removePoint(index),
                      icon: const Icon(AppIcons.delete),
                    ),
                    title: Text(
                      "${index + 1}",
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    trailing: const Icon(AppIcons.dragHandle),
                    dense: true,
                  ),
                  itemCount: _route.markedPositions!.length,
                  onReorder: _switchPoints,
                  shrinkWrap: true,
                ),
              ),
            ],
          )
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _listExpanded = true;
              }),
              child: const Text("show List"),
            ),
          );
  }

  Future<void> _setBoundsAndPointsAndLine() async {
    await _mapController.setBoundsFromTracks(
      _route.track,
      _route.markedPositions,
      padded: true,
    );
    await _updatePoints();
    await _updateLine();
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.route != null ? "Edit Route" : "Create Route"),
          actions: [
            IconButton(
              onPressed: _deleteRoute,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _route.isValid()
                  ? _saveRoute
                  : null,
              icon: const Icon(AppIcons.save),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: MapboxMapWrapper(
                showScale: true,
                showMapStylesButton: true,
                showCurrentLocationButton: false,
                showSetNorthButton: true,
                onMapCreated: (MapboxMapController controller) =>
                    _mapController = controller,
                onStyleLoadedCallback: _setBoundsAndPointsAndLine,
                onMapLongClick: (point, LatLng latLng) => _extendLine(latLng),
              ),
            ),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Column(
                children: [
                  _buildExpandableListContainer(),
                  const Divider(),
                  Defaults.sizedBox.vertical.normal,
                  RouteValueUnitDescriptionTable(route: _route),
                  Defaults.sizedBox.vertical.normal,
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      onTap: () => setState(() => _listExpanded = false),
                      onChanged: (name) => setState(() => _route.name = name),
                      initialValue: _route.name,
                      validator: Validator.validateStringNotEmpty,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                labelText: "Name",
                              ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
