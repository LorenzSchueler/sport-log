import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';

class RoutePlanningPage extends StatefulWidget {
  const RoutePlanningPage({Key? key}) : super(key: key);

  @override
  State<RoutePlanningPage> createState() => RoutePlanningPageState();
}

class RoutePlanningPageState extends State<RoutePlanningPage> {
  final _logger = Logger('RoutePlanningPage');

  final String token = Secrets.mapboxAccessToken;
  final String style = 'mapbox://styles/mapbox/outdoors-v11';

  List<LatLng> locations = [];
  Line? line;
  List<Circle> circles = [];
  List<Symbol> symbols = [];

  late MapboxMapController mapController;

  void markLatLng(
      MapboxMapController controller, LatLng latLng, int number) async {
    symbols.add(await controller.addSymbol(SymbolOptions(
        textField: "$number",
        textOffset: const Offset(0, 1),
        geometry: latLng)));
    circles.add(await controller.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#0060a0',
        circleOpacity: 0.5,
        geometry: latLng,
        draggable: false,
      ),
    ));
  }

  void extendLine(MapboxMapController controller, LatLng location) async {
    setState(() {
      locations.add(location);
    });
    markLatLng(controller, location, locations.length);
    line ??= await controller.addLine(
        const LineOptions(lineColor: "red", lineWidth: 3, geometry: []));
    await controller.updateLine(line, LineOptions(geometry: locations));
  }

  void switchOrder(
      MapboxMapController controller, int oldIndex, int newIndex) async {
    setState(() {
      _logger.i("old: $oldIndex, new: $newIndex");
      if (oldIndex < newIndex - 1) {
        LatLng location = locations.removeAt(oldIndex);
        if (newIndex - 1 == locations.length) {
          locations.add(location);
        } else {
          locations.insert(newIndex - 1, location);
        }
      } else if (oldIndex > newIndex) {
        locations.insert(newIndex, locations.removeAt(oldIndex));
      }
    });

    await controller.removeCircles(circles);
    circles = [];
    await controller.removeSymbols(symbols);
    symbols = [];
    locations.asMap().forEach((index, latLng) {
      markLatLng(controller, latLng, index + 1);
    });
    await controller.updateLine(line, LineOptions(geometry: locations));
  }

  Widget _buildCard(String title, String subtitle) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(top: 2),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25),
        ),
        subtitle: Text(
          subtitle,
          textAlign: TextAlign.center,
        ),
        dense: true,
      ),
    );
  }

  Widget _buildDraggableList(List<LatLng> locations) {
    List<Widget> listElements = [];
    for (int index = 0; index < locations.length; index++) {
      listElements.add(
        DragTarget(
            onWillAccept: (value) => true,
            onAccept: (value) =>
                switchOrder(mapController, value as int, index),
            builder: (context, candidates, reject) {
              if (candidates.isNotEmpty) {
                int index = candidates[0] as int;
                return ListTile(
                  trailing: const Icon(
                    Icons.drag_handle,
                    color: Colors.red,
                  ),
                  title: Text("${index + 1}"),
                  dense: true,
                );
              } else {
                return const Divider();
              }
            }),
      );

      ListTile listTile = ListTile(
        trailing: const Icon(
          Icons.drag_handle,
        ),
        title: Text("${index + 1}"),
        dense: true,
      );

      listElements.add(
        Draggable(
          data: index,
          child: listTile,
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: listTile,
          ),
          feedback: Text("${index + 1}"),
        ),
      );
    }

    listElements.add(
      DragTarget(
          onWillAccept: (value) => true,
          onAccept: (value) =>
              switchOrder(mapController, value as int, locations.length),
          builder: (context, candidates, reject) {
            if (candidates.isNotEmpty) {
              int index = candidates[0] as int;
              return ListTile(
                trailing: const Icon(
                  Icons.drag_handle,
                  color: Colors.red,
                ),
                title: Text("${index + 1}"),
                dense: true,
              );
            } else {
              return const Divider();
            }
          }),
    );

    return ListView(children: listElements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      Expanded(
          child: MapboxMap(
        accessToken: token,
        styleString: style,
        initialCameraPosition: const CameraPosition(
          zoom: 13.0,
          target: LatLng(47.27, 11.33),
        ),
        compassEnabled: true,
        compassViewPosition: CompassViewPosition.TopRight,
        onMapCreated: (MapboxMapController controller) =>
            mapController = controller,
        onMapLongClick: (point, LatLng coordinates) =>
            extendLine(mapController, coordinates),
      )),
      Container(
        height: 350,
        color: onPrimaryColorOf(context),
        child: _buildDraggableList(locations),
      ),
      Container(
          padding: const EdgeInsets.all(5),
          color: onPrimaryColorOf(context),
          child: Table(
            children: [
              TableRow(children: [
                _buildCard("6.17 km", "distance"),
                _buildCard("???", "???"),
              ]),
              TableRow(children: [
                _buildCard("231 m", "ascent"),
                _buildCard("51 m", "descent"),
              ]),
            ],
          )),
      Container(
          color: onPrimaryColorOf(context),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              const Expanded(
                  child: TextField(
                decoration: InputDecoration(
                  labelText: "name",
                ),
              )),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                  onPressed: null,
                  //onPressed: () => updateLocations(mapController),
                  child: const Text("create")),
            ],
          ))
    ]));
  }
}
