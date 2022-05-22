import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  State<RoutePage> createState() => RoutePageState();
}

class RoutePageState extends State<RoutePage> {
  final _logger = Logger('RoutePage');
  final _dataProvider = RouteDataProvider();
  List<Route> _routes = [];

  @override
  void initState() {
    super.initState();
    _dataProvider
      ..addListener(_update)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider
      ..removeListener(_update)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d('Updating route page');
    final routes = await _dataProvider.getNonDeleted();
    setState(() => _routes = routes);
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Routes"),
          actions: [
            IconButton(
              onPressed: () =>
                  Navigator.of(context).newBase(Routes.cardio.overview),
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
        bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
          context,
          SessionsPageTab.cardio,
        ),
        drawer: MainDrawer(selectedRoute: Routes.cardio.routeOverview),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, Routes.cardio.routeEdit),
          child: const Icon(AppIcons.add),
        ),
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
    late MapboxMapController sessionMapController;

    return GestureDetector(
      onTap: () => showDetails(context),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Text(
                route.name,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            route.track != null && route.track!.isNotEmpty
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                      accessToken: Config.instance.accessToken,
                      styleString: MapboxStyles.OUTDOORS,
                      initialCameraPosition: Settings.lastMapPosition,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      onMapCreated: (MapboxMapController controller) =>
                          sessionMapController = controller,
                      onStyleLoadedCallback: () {
                        sessionMapController.setBoundsFromTracks(
                          route.track,
                          null,
                          padded: true,
                        );
                        if (route.track != null) {
                          sessionMapController.addRouteLine(route.track!);
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
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueUnitDescription.distanceSmall(route.distance),
                  ValueUnitDescription.ascentSmall(route.ascent),
                  ValueUnitDescription.descentSmall(route.descent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
