import 'package:flutter/material.dart' hide Route;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/all.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:sport_log/widgets/app_icons.dart';
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
  final _dataProvider = RouteDataProvider.instance;

  List<LatLng> _locations = [];

  Line? _line;
  List<Circle> _circles = [];
  List<Symbol> _symbols = [];

  bool _listExpanded = false;

  late MapboxMapController _mapController;

  MapboxApi mapbox = MapboxApi(accessToken: Defaults.mapbox.accessToken);

  late Route _route;

  @override
  void initState() {
    _route = widget.route?.clone() ?? Route.defaultValue();
    // TODO dont map every point to marked location
    _locations =
        _route.track.map((e) => LatLng(e.latitude, e.longitude)).toList();
    super.initState();
  }

  Future<void> _saveRoute() async {
    final result = widget.route != null
        ? await _dataProvider.updateSingle(_route)
        : await _dataProvider.createSingle(_route);
    if (result) {
      _formKey.currentState!.deactivate();
      Navigator.pop(context);
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Route Entry failed.',
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
    DirectionsApiResponse response = await mapbox.directions.request(
      profile: NavigationProfile.WALKING,
      geometries: NavigationGeometries.POLYLINE,
      coordinates: _locations.map((e) => [e.latitude, e.longitude]).toList(),
    );
    if (response.error != null) {
      if (response.error is NavigationNoRouteError) {
        _logger.i(response.error);
      } else if (response.error is NavigationNoSegmentError) {
        _logger.i(response.error);
      }
    } else if (response.routes != null && response.routes!.isNotEmpty) {
      NavigationRoute navRoute = response.routes![0];
      setState(() {
        _route.distance = navRoute.distance!.round();
      });

      _route.track = PolylinePoints()
          .decodePolyline(navRoute.geometry as String)
          .map(
            (coordinate) => Position(
              latitude: coordinate.latitude,
              longitude: coordinate.longitude,
              elevation: 0, // TODO
              distance: 0, // TODO
              time: const Duration(seconds: 0),
            ), // TODO
          )
          .toList();
    }
  }

  Future<void> _updateLine() async {
    await _matchLocations();
    await _mapController.updateLine(
      _line!,
      LineOptions(geometry: _route.track.map((e) => e.latLng).toList()),
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
    _circles.add(
      await _mapController.addCircle(
        CircleOptions(
          circleRadius: 8.0,
          circleColor: Defaults.mapbox.markerColor,
          circleOpacity: 0.5,
          geometry: latLng,
          draggable: false,
        ),
      ),
    );
  }

  Future<void> _updatePoints() async {
    await _mapController.removeCircles(_circles);
    _circles = [];
    await _mapController.removeSymbols(_symbols);
    _symbols = [];
    _locations.asMap().forEach((index, latLng) {
      _addPoint(latLng, index + 1);
    });
  }

  Future<void> _extendLine(LatLng location) async {
    if (_locations.length == 25) {
      await showMessageDialog(
        context: context,
        title: "Point maximum reached",
        text: "You can only set 25 points.",
      );
      return;
    }
    setState(() {
      _locations.add(location);
    });
    _addPoint(location, _locations.length);
    await _updateLine();
  }

  Future<void> _removePoint(int index) async {
    setState(() {
      _locations.removeAt(index);
    });
    await _updatePoints();
    await _updateLine();
  }

  Future<void> _switchPoints(int oldIndex, int newIndex) async {
    setState(() {
      _logger.i("old: $oldIndex, new: $newIndex");
      if (oldIndex < newIndex - 1) {
        LatLng location = _locations.removeAt(oldIndex);
        if (newIndex - 1 == _locations.length) {
          _locations.add(location);
        } else {
          _locations.insert(newIndex - 1, location);
        }
      } else if (oldIndex > newIndex) {
        _locations.insert(newIndex, _locations.removeAt(oldIndex));
      }
    });

    await _updatePoints();
    await _updateLine();
  }

  Widget _buildDraggableList() {
    List<Widget> listElements = [];

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
                child: const Icon(
                  AppIcons.add,
                ),
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

    for (int index = 0; index < _locations.length; index++) {
      listElements.add(_buildDragTarget(index));

      var icon = const Icon(
        AppIcons.dragHandle,
      );
      Text title = Text(
        "${index + 1}",
        style: const TextStyle(fontSize: 20),
      );
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
          title: title,
          dense: true,
        ),
      );
    }

    listElements.add(_buildDragTarget(_locations.length));

    return ListView(children: listElements);
  }

  Widget _buildExpandableListContainer() {
    if (_listExpanded) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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
            Expanded(
              child: _buildDraggableList(),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        color: onPrimaryColorOf(context),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: ElevatedButton(
          onPressed: () => setState(() {
            _listExpanded = true;
          }),
          child: const Text("show List"),
        ),
      );
    }
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
      body: Container(
        color: backgroundColorOf(context),
        child: Column(
          children: [
            Expanded(
              child: MapboxMap(
                accessToken: Defaults.mapbox.accessToken,
                styleString: Defaults.mapbox.style.outdoor,
                initialCameraPosition: CameraPosition(
                  zoom: 13.0,
                  target: Defaults.mapbox.cameraPosition,
                ),
                compassEnabled: true,
                compassViewPosition: CompassViewPosition.TopRight,
                onMapCreated: (MapboxMapController controller) async {
                  _mapController = controller;
                  _line ??= await _mapController.addLine(
                    const LineOptions(
                      lineColor: "red",
                      lineWidth: 3,
                      geometry: [],
                    ),
                  );
                  _updatePoints();
                  _updateLine();
                },
                onMapLongClick: (point, LatLng latLng) => _extendLine(latLng),
              ),
            ),
            _buildExpandableListContainer(),
            Table(
              children: [
                TableRow(
                  children: [
                    ValueUnitDescription(
                      value: (_route.distance / 1000).toString(),
                      unit: "km",
                      description: "distance",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: _route.name,
                      unit: null,
                      description: "Name",
                      scale: 1.3,
                    )
                  ],
                ),
                rowSpacer,
                TableRow(
                  children: [
                    ValueUnitDescription(
                      value: _route.ascent?.toString() ?? "--",
                      unit: "m",
                      description: "ascent",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: _route.descent?.toString() ?? "--",
                      unit: "m",
                      description: "descent",
                      scale: 1.3,
                    ),
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
      ),
    );
  }
}
