import 'package:flutter/material.dart' hide Route;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/all.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RouteEditPage extends StatefulWidget {
  final Route? route;

  const RouteEditPage({Key? key, this.route}) : super(key: key);

  @override
  State<RouteEditPage> createState() => RouteEditPageState();
}

class RouteEditPageState extends State<RouteEditPage> {
  final _logger = Logger('RouteEditPage');
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = RouteDataProvider();

  Line? _line;
  List<Circle> _circles = [];
  List<Symbol> _symbols = [];

  bool _listExpanded = false;

  late MapboxMapController _mapController;

  late Route _route;

  @override
  void initState() {
    _route = widget.route?.clone() ?? Route.defaultValue();
    _route.track ??= [];
    _route.markedPositions ??= [];
    super.initState();
  }

  @override
  void dispose() {
    if (_mapController.cameraPosition != null) {
      Settings.lastMapPosition = _mapController.cameraPosition!;
    }
    super.dispose();
  }

  Future<void> _saveRoute() async {
    _logger.i("saving route");
    final result = widget.route != null
        ? await _dataProvider.updateSingle(_route)
        : await _dataProvider.createSingle(_route);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      Navigator.pop(context);
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
    Navigator.pop(context);
  }

  Future<void> _matchLocations() async {
    DirectionsApiResponse response =
        await Defaults.mapboxApi.directions.request(
      profile: NavigationProfile.WALKING,
      geometries: NavigationGeometries.POLYLINE,
      coordinates: _route.markedPositions!
          .map((e) => [e.latitude, e.longitude])
          .toList(),
    );
    if (response.error != null) {
      if (response.error is NavigationNoRouteError) {
        _logger.i(response.error);
      } else if (response.error is NavigationNoSegmentError) {
        _logger.i(response.error);
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
          ..distance = track.last.distance.round()
          ..track = track;
      });
    }
  }

  Future<void> _updateLine() async {
    await _matchLocations();
    await _mapController.updateLine(
      _line!,
      LineOptions(
        lineWidth: 2,
        geometry: _route.track?.latLngs,
      ),
    );
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

  Widget _buildDragTarget(int index) {
    return DragTarget(
      onWillAccept: (value) => true,
      onAccept: (value) => _switchPoints(value as int, index),
      builder: (context, candidates, reject) {
        if (candidates.isNotEmpty) {
          int index = candidates[0] as int;
          return ListTile(
            leading: Container(
              margin: const EdgeInsets.only(left: 12),
              child: const Icon(AppIcons.add),
            ),
            title: Text(
              "${index + 1}",
              style: const TextStyle(fontSize: 20),
            ),
            dense: true,
          );
        } else {
          return const Divider();
        }
      },
    );
  }

  Widget _buildDraggableList() {
    List<Widget> listElements = [];

    for (int index = 0; index < _route.markedPositions!.length; index++) {
      listElements.add(_buildDragTarget(index));

      var icon = const Icon(AppIcons.dragHandle);
      listElements.add(
        ListTile(
          leading: IconButton(
            onPressed: () => _removePoint(index),
            icon: const Icon(AppIcons.delete),
          ),
          trailing: Draggable(
            axis: Axis.vertical,
            data: index,
            child: icon,
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: icon,
            ),
            feedback: icon,
          ),
          title: Text(
            "${index + 1}",
            style: const TextStyle(fontSize: 20),
          ),
          dense: true,
        ),
      );
    }

    listElements.add(_buildDragTarget(_route.markedPositions!.length));

    return ListView(children: listElements);
  }

  Widget _buildExpandableListContainer() {
    return _listExpanded
        ? Container(
            padding: Defaults.edgeInsets.normal,
            height: 350,
            child: Column(
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
                Expanded(child: _buildDraggableList())
              ],
            ),
          )
        : Container(
            width: double.infinity,
            padding: Defaults.edgeInsets.normal,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _listExpanded = true;
              }),
              child: const Text("show List"),
            ),
          );
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
        title: Text(widget.route != null ? "Edit Route" : "Create Route"),
        leading: IconButton(
          onPressed: () async {
            final bool? approved = await showDiscardWarningDialog(context);
            if (approved != null && approved) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(AppIcons.arrowBack),
        ),
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
            child: MapboxMap(
              accessToken: Config.instance.accessToken,
              styleString: Defaults.mapbox.style.outdoor,
              initialCameraPosition: Settings.lastMapPosition,
              trackCameraPosition: true,
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.TopRight,
              onMapCreated: (MapboxMapController controller) async {
                _mapController = controller;
              },
              onStyleLoadedCallback: () async {
                await _mapController.setBounds(
                  _route.track,
                  _route.markedPositions,
                );
                _line ??= await _mapController.addRouteLine([]);
                await _updatePoints();
                await _updateLine();
              },
              onMapLongClick: (point, LatLng latLng) => _extendLine(latLng),
            ),
          ),
          _buildExpandableListContainer(),
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
          Defaults.sizedBox.vertical.normal,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: _formKey,
              child: TextFormField(
                onTap: () => setState(() {
                  _listExpanded = false;
                }),
                onChanged: (name) => setState(() => _route.name = name),
                initialValue: _route.name,
                validator: Validator.validateStringNotEmpty,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(height: 1),
                decoration: const InputDecoration(
                  labelText: "Name",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
            ),
          ),
          Defaults.sizedBox.vertical.normal,
        ],
      ),
    );
  }
}
