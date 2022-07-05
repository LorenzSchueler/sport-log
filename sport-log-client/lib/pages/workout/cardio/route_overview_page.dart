import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/overview_data_provider.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RoutePage extends StatelessWidget {
  const RoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<Route, void, RouteDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: RouteDataProvider(),
          entityAccessor: (dataProvider) =>
              (_, __, ___) => dataProvider.getNonDeleted(),
          recordAccessor: (_) => () async {},
          loggerName: "RoutePage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
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
            onRefresh: dataProvider.pullFromServer,
            child: dataProvider.entities.isEmpty
                ? const Center(
                    child: Text(
                      "looks like there are no routes there yet 😔 \npress ＋ to create a new one",
                      textAlign: TextAlign.center,
                    ),
                  )
                : Container(
                    padding: Defaults.edgeInsets.normal,
                    child: ListView.separated(
                      itemBuilder: (_, index) => RouteCard(
                        route: dataProvider.entities[index],
                        key: ValueKey(dataProvider.entities[index].id),
                      ),
                      separatorBuilder: (_, __) =>
                          Defaults.sizedBox.vertical.normal,
                      itemCount: dataProvider.entities.length,
                    ),
                  ),
          ),
          bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
            context: context,
            sessionsPageTab: SessionsPageTab.cardio,
          ),
          drawer: MainDrawer(selectedRoute: Routes.cardio.routeOverview),
          floatingActionButton: ExpandableFab(
            icon: const Icon(AppIcons.add),
            buttons: [
              ActionButton(
                icon: const Icon(AppIcons.route),
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.cardio.routeEdit,
                ),
              ),
              ActionButton(
                icon: const Icon(AppIcons.upload),
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.cardio.routeUpload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  const RouteCard({required this.route, super.key});

  final Route route;

  void showDetails(BuildContext context) {
    Navigator.pushNamed(context, Routes.cardio.routeDetails, arguments: route);
  }

  Future<void> _setBoundsAndTrack(
    MapboxMapController sessionMapController,
  ) async {
    await sessionMapController.setBoundsFromTracks(
      route.track,
      null,
      padded: true,
    );
    if (route.track != null) {
      await sessionMapController.addRouteLine(route.track!);
    }
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
                      key:
                          ObjectKey(route), // update on relaod to get new track
                      accessToken: Config.instance.accessToken,
                      styleString: MapboxStyles.OUTDOORS,
                      initialCameraPosition:
                          context.read<Settings>().lastMapPosition,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      onMapCreated: (MapboxMapController controller) =>
                          sessionMapController = controller,
                      onStyleLoadedCallback: () =>
                          _setBoundsAndTrack(sessionMapController),
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
