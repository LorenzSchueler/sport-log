import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  State<RoutePage> createState() => RoutePageState();
}

class RoutePageState extends State<RoutePage> {
  final _logger = Logger('RoutePage');

  final List<Route> _routes = [
    Route(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        name: "my route 1",
        distance: 10951,
        ascent: 456,
        descent: 476,
        track: [
          Position(
              longitude: 11.33,
              latitude: 47.27,
              elevation: 600,
              distance: 0,
              time: 0),
          Position(
              longitude: 11.331,
              latitude: 47.27,
              elevation: 650,
              distance: 1000,
              time: 200),
          Position(
              longitude: 11.33,
              latitude: 47.272,
              elevation: 600,
              distance: 2000,
              time: 500)
        ],
        deleted: false)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("routes"),
      ),
      body: Scrollbar(
          child: ListView.builder(
        itemBuilder: _buildSessionCard,
        itemCount: _routes.length,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      )),
      drawer: const MainDrawer(selectedRoute: Routes.workout),
    );
  }

  void showDetails(BuildContext context, Route route) {
    //Navigator.of(context)
    //.pushNamed(Routes.cardio.cardio_details, arguments: route);
  }

  Widget _buildSessionCard(BuildContext buildContext, int index) {
    final Route route = _routes[index];
    final distance = (route.distance / 1000).toStringAsFixed(3);

    late MapboxMapController _sessionMapController;

    return GestureDetector(
        onTap: () {
          _logger.i("click");
          showDetails(context, route);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Defaults.borderRadius.normal,
            color: backgroundColorOf(context),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(children: [
            Defaults.sizedBox.vertical.small,
            Text(
              route.name,
              textAlign: TextAlign.center,
            ),
            Defaults.sizedBox.vertical.small,
            SizedBox(
                height: 150,
                child: MapboxMap(
                    accessToken: Secrets.mapboxAccessToken,
                    styleString: Defaults.mapbox.style.outdoor,
                    initialCameraPosition: CameraPosition(
                      zoom: 13.0,
                      target: route.track.first.latLng,
                    ),
                    onMapCreated: (MapboxMapController controller) =>
                        _sessionMapController = controller,
                    onStyleLoadedCallback: () {
                      _sessionMapController.addLine(LineOptions(
                          lineColor: "red",
                          geometry: route.track.map((c) => c.latLng).toList()));
                    },
                    onMapClick: (_, __) {
                      // TODO does not work
                      _logger.i("map click");
                      showDetails(context, route);
                    },
                    onMapLongClick: (_, __) {
                      _logger.i("map long click");
                      showDetails(context, route);
                    })),
            Defaults.sizedBox.vertical.small,
            Row(children: [
              Expanded(
                child: ValueUnitDescription(
                  value: distance,
                  unit: "km",
                  description: null,
                ),
              ),
              Expanded(
                child: ValueUnitDescription(
                  value: route.ascent.toString(),
                  unit: "m",
                  description: null,
                ),
              ),
              Expanded(
                child: ValueUnitDescription(
                  value: route.descent.toString(),
                  unit: "m",
                  description: null,
                ),
              ),
            ]),
          ]),
        ));
  }
}
