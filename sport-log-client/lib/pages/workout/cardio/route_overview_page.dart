import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
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
        () => showSimpleToast(context, 'No Internet connection.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Routes"),
        actions: [
          IconButton(
            onPressed: () => Nav.newBase(context, Routes.cardio.overview),
            icon: const Icon(AppIcons.heartbeat),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _dataProvider.pullFromServer,
        child: _routes.isEmpty
            ? const Center(
                child: Text(
                  "looks like there are no routes there yet 😔 \npress ＋ to create a new one",
                  textAlign: TextAlign.center,
                ),
              )
            : Container(
                padding: Defaults.edgeInsets.normal,
                child: ListView.separated(
                  itemBuilder: (_, index) => RouteCard(route: _routes[index]),
                  separatorBuilder: (_, __) =>
                      Defaults.sizedBox.vertical.normal,
                  itemCount: _routes.length,
                ),
              ),
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.cardio),
      drawer: MainDrawer(selectedRoute: Routes.cardio.routeOverview),
      floatingActionButton: FloatingActionButton(
        onPressed: () async =>
            await Navigator.pushNamed(context, Routes.cardio.routeEdit),
        child: const Icon(AppIcons.add),
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final Route route;

  const RouteCard({required this.route, Key? key}) : super(key: key);

  void showDetails(BuildContext context) {
    Navigator.pushNamed(context, Routes.cardio.routeEdit, arguments: route);
  }

  @override
  Widget build(BuildContext context) {
    final distance = (route.distance / 1000).toStringAsFixed(3);

    late MapboxMapController _sessionMapController;

    return GestureDetector(
      onTap: () => showDetails(context),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Defaults.sizedBox.vertical.small,
            Text(
              route.name,
              textAlign: TextAlign.center,
            ),
            Defaults.sizedBox.vertical.small,
            route.track != null && route.track!.isNotEmpty
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                      accessToken: Defaults.mapbox.accessToken,
                      styleString: Defaults.mapbox.style.outdoor,
                      initialCameraPosition: Settings.lastMapPosition,
                      onMapCreated: (MapboxMapController controller) =>
                          _sessionMapController = controller,
                      onStyleLoadedCallback: () {
                        if (route.track != null) {
                          final bounds = route.track!.latLngBounds;
                          _sessionMapController
                              .moveCamera(CameraUpdate.newLatLngBounds(bounds));
                          _sessionMapController.addLine(
                            LineOptions(
                              lineColor: Defaults.mapbox.routeLineColor,
                              lineWidth: 2,
                              geometry: route.track?.latLngs,
                            ),
                          );
                        }
                      },
                      onMapClick: (_, __) => showDetails(context),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.route,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const Text(" no track available"),
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
