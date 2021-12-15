import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:polyline/polyline.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RoutePlanningPage extends StatefulWidget {
  const RoutePlanningPage({Key? key}) : super(key: key);

  @override
  State<RoutePlanningPage> createState() => RoutePlanningPageState();
}

class RoutePlanningPageState extends State<RoutePlanningPage> {
  final _logger = Logger('RoutePlanningPage');

  final String _token = Secrets.mapboxAccessToken;

  final List<LatLng> _locations = [];
  List<LatLng> _matchedLocations = [];

  Line? _line;
  List<Circle> _circles = [];
  List<Symbol> _symbols = [];

  bool _listExpanded = false;

  late MapboxMapController _mapController;

  int _distance = 0;
  String _routeName = "";
  MapboxApi mapbox = MapboxApi(accessToken: Secrets.mapboxAccessToken);

  Future<void> _matchLocations() async {
    DirectionsApiResponse response = await mapbox.directions.request(
      profile: NavigationProfile.WALKING,
      geometries: NavigationGeometries.POLYLINE6,
      coordinates: _locations.map((e) => [e.latitude, e.longitude]).toList(),
    );
    if (response.error != null) {
      if (response.error is NavigationNoRouteError) {
        _logger.i(response.error);
      } else if (response.error is NavigationNoSegmentError) {
        _logger.i(response.error);
      }
    } else if (response.routes != null && response.routes!.isNotEmpty) {
      NavigationRoute route = response.routes![0];
      setState(() {
        _distance = route.distance!.round();
      });

      _matchedLocations = Polyline.Decode(
        encodedString: route.geometry as String,
        precision: 6,
      )
          .decodedCoords
          .map(
            (coordinate) => LatLng(
              coordinate[0],
              coordinate[1],
            ),
          )
          .toList();
    }
  }

  void _saveRoute() {
    Route route = Route(
      id: randomId(),
      userId: UserState.instance.currentUser!.id,
      name: _routeName,
      distance: _distance,
      ascent: null, // TODO
      descent: null, //TODO
      track: _matchedLocations
          .map((position) => Position(
              longitude: position.longitude,
              latitude: position.latitude,
              elevation: 0, //TODO
              distance: 0, //TODO
              time: 0))
          .toList(),
      deleted: false,
    );
  }

  void _addPoint(LatLng latLng, int number) async {
    _symbols.add(await _mapController.addSymbol(SymbolOptions(
        textField: "$number",
        textOffset: const Offset(0, 1),
        geometry: latLng)));
    _circles.add(await _mapController.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#0060a0',
        circleOpacity: 0.5,
        geometry: latLng,
        draggable: false,
      ),
    ));
  }

  Future<void> _updateLine() async {
    await _matchLocations();
    await _mapController.updateLine(
        _line!, LineOptions(geometry: _matchedLocations));
  }

  void _extendLine(LatLng location) async {
    if (_locations.length == 25) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Point maximum reached"),
          content: const Text("You can only set 25 points."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        ),
      );
      return;
    }
    setState(() {
      _locations.add(location);
    });
    _addPoint(location, _locations.length);
    _line ??= await _mapController.addLine(
        const LineOptions(lineColor: "red", lineWidth: 3, geometry: []));
    await _updateLine();
  }

  void _removePoint(int index) async {
    setState(() {
      _locations.removeAt(index);
    });
    await _mapController.removeCircles(_circles);
    _circles = [];
    await _mapController.removeSymbols(_symbols);
    _symbols = [];
    _locations.asMap().forEach((index, latLng) {
      _addPoint(latLng, index + 1);
    });
    await _updateLine();
  }

  void _switchPoints(int oldIndex, int newIndex) async {
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

    await _mapController.removeCircles(_circles);
    _circles = [];
    await _mapController.removeSymbols(_symbols);
    _symbols = [];
    _locations.asMap().forEach((index, latLng) {
      _addPoint(latLng, index + 1);
    });
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
                    Icons.add_rounded,
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
          });
    }

    for (int index = 0; index < _locations.length; index++) {
      listElements.add(_buildDragTarget(index));

      var icon = const Icon(
        Icons.drag_handle,
      );
      Text title = Text(
        "${index + 1}",
        style: const TextStyle(fontSize: 20),
      );
      listElements.add(ListTile(
        leading: IconButton(
            onPressed: () => _removePoint(index),
            icon: const Icon(Icons.delete_rounded)),
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
      ));
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
          ));
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
    TableRow rowSpacer = TableRow(children: [
      Defaults.sizedBox.vertical.normal,
      Defaults.sizedBox.vertical.normal,
    ]);

    return Scaffold(
        body: Container(
            color: backgroundColorOf(context),
            child: Column(children: [
              Expanded(
                  child: MapboxMap(
                accessToken: _token,
                styleString: Defaults.mapbox.style.outdoor,
                initialCameraPosition: const CameraPosition(
                  zoom: 13.0,
                  target: LatLng(47.27, 11.33),
                ),
                compassEnabled: true,
                compassViewPosition: CompassViewPosition.TopRight,
                onMapCreated: (MapboxMapController controller) =>
                    _mapController = controller,
                onMapLongClick: (point, LatLng latLng) => _extendLine(latLng),
              )),
              _buildExpandableListContainer(),
              Table(
                children: [
                  TableRow(children: [
                    ValueUnitDescription(
                      value: (_distance / 1000).toString(),
                      unit: "km",
                      description: "distance",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: "???",
                      unit: null,
                      description: null,
                      scale: 1.3,
                    )
                  ]),
                  rowSpacer,
                  TableRow(children: [
                    ValueUnitDescription(
                      value: 231.toString(),
                      unit: "m",
                      description: "ascent",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: 51.toString(),
                      unit: "m",
                      description: "descent",
                      scale: 1.3,
                    ),
                  ]),
                ],
              ),
              Defaults.sizedBox.vertical.normal,
              Row(
                children: [
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(
                      child: TextFormField(
                    onTap: () => setState(() {
                      _listExpanded = false;
                    }),
                    onFieldSubmitted: (name) => setState(() {
                      _routeName = name;
                    }),
                    style: const TextStyle(height: 1),
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                          borderRadius: Defaults.borderRadius.big),
                    ),
                  )),
                  Defaults.sizedBox.horizontal.big,
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green[400],
                      ),
                      onPressed:
                          _routeName.isNotEmpty ? () => _saveRoute() : null,
                      child: const Text("create")),
                  Defaults.sizedBox.horizontal.normal,
                ],
              ),
              Defaults.sizedBox.vertical.normal,
            ])));
  }
}
