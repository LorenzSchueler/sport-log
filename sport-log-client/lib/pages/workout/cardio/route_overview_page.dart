import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
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
  final _dataProvider = RouteDataProvider.instance;
  List<Route> _routes = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _dataProvider.onNoInternetConnection =
        () => showSimpleSnackBar(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    _dataProvider.onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d('Updating route page');
    final routes = await _dataProvider.getNonDeleted();
    setState(() => _routes = routes);
  }

  Future<void> _pullFromServer() async {
    await _dataProvider.pullFromServer().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Routes"),
        actions: [
          IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.cardio.overview),
              icon: const Icon(CustomIcons.heartbeat)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _pullFromServer,
        child: ListView.builder(
          itemBuilder: (_, index) => RouteCard(route: _routes[index]),
          itemCount: _routes.length,
        ),
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.cardio),
      drawer: MainDrawer(selectedRoute: Routes.cardio.routeOverview),
      floatingActionButton: FloatingActionButton(
        onPressed: () async =>
            await Navigator.of(context).pushNamed(Routes.cardio.routeEdit),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final Route route;

  const RouteCard({required this.route, Key? key}) : super(key: key);

  void showDetails(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.cardio.routeEdit, arguments: route);
  }

  @override
  Widget build(BuildContext context) {
    final distance = (route.distance / 1000).toStringAsFixed(3);

    late MapboxMapController _sessionMapController;

    return GestureDetector(
      onTap: () => showDetails(context),
      child: Card(
        child: Column(
          children: [
            Defaults.sizedBox.vertical.small,
            Text(
              route.name,
              textAlign: TextAlign.center,
            ),
            Defaults.sizedBox.vertical.small,
            route.track.isNotEmpty
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                      accessToken: Defaults.mapbox.accessToken,
                      styleString: Defaults.mapbox.style.outdoor,
                      initialCameraPosition: CameraPosition(
                        zoom: 13.0,
                        target: route.track.isEmpty
                            ? Defaults.mapbox.cameraPosition
                            : route.track.first.latLng,
                      ),
                      onMapCreated: (MapboxMapController controller) =>
                          _sessionMapController = controller,
                      onStyleLoadedCallback: () {
                        _sessionMapController.addLine(LineOptions(
                            lineColor: "red",
                            geometry:
                                route.track.map((c) => c.latLng).toList()));
                      },
                      onMapClick: (_, __) => showDetails(context),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CustomIcons.route),
                      Text(" no track available"),
                    ],
                  ),
            Defaults.sizedBox.vertical.small,
            Row(
              children: [
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
              ],
            ),
            Defaults.sizedBox.vertical.small,
          ],
        ),
      ),
    );
  }
}
