import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/cardio/no_track.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RouteOverviewPage extends StatelessWidget {
  RouteOverviewPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child:
          ProviderConsumer<
            OverviewDataProvider<Route, void, RouteDataProvider, void>
          >(
            create: (_) => OverviewDataProvider(
              dataProvider: RouteDataProvider(),
              entityAccessor: (dataProvider) =>
                  (_, _, _, search) => dataProvider.getByName(search),
              recordAccessor: (_) => () async {},
              loggerName: "RoutePage",
            ),
            builder: (_, dataProvider, _) => Scaffold(
              appBar: AppBar(
                title: dataProvider.isSearch
                    ? TextFormField(
                        focusNode: _searchBar,
                        onChanged: (name) => dataProvider.search = name,
                      )
                    : const Text("Routes"),
                actions: [
                  IconButton(
                    onPressed: () {
                      dataProvider.search = dataProvider.isSearch ? null : "";
                      if (dataProvider.isSearch) {
                        _searchBar.requestFocus();
                      }
                    },
                    icon: Icon(
                      dataProvider.isSearch ? AppIcons.close : AppIcons.search,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).newBase(Routes.cardioOverview),
                    icon: const Icon(AppIcons.heartbeat),
                  ),
                ],
              ),
              body: SyncRefreshIndicator(
                child: dataProvider.entities.isEmpty
                    ? const RefreshableNoEntriesText(
                        text:
                            "Looks like there are no routes there yet 😔\nPress ＋ to create a new one",
                      )
                    : Padding(
                        padding: Defaults.edgeInsets.normal,
                        child: ListView.separated(
                          itemBuilder: (_, index) => RouteCard(
                            route: dataProvider.entities[index],
                            key: ValueKey(dataProvider.entities[index].id),
                          ),
                          separatorBuilder: (_, _) =>
                              Defaults.sizedBox.vertical.normal,
                          itemCount: dataProvider.entities.length,
                        ),
                      ),
              ),
              bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
                context: context,
                sessionsPageTab: SessionsPageTab.cardio,
              ),
              drawer: const MainDrawer(selectedRoute: Routes.routeOverview),
              floatingActionButton: ExpandableFab(
                icon: const Icon(AppIcons.add),
                buttons: [
                  ActionButton(
                    icon: const Icon(AppIcons.route),
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.routeEdit),
                  ),
                  ActionButton(
                    icon: const Icon(AppIcons.upload),
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.routeUpload),
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
    Navigator.pushNamed(context, Routes.routeDetails, arguments: route);
  }

  Future<void> _onMapCreated(MapController mapController) async {
    await mapController.setBoundsFromTracks(route.track, null, padded: true);
    if (route.track != null) {
      await mapController.addRouteLine(route.track!);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            route.track != null && route.track!.isNotEmpty
                ? SizedBox(
                    height: 150,
                    child: StaticMapboxMap(
                      key: ObjectKey(
                        route,
                      ), // update on reload to get new track
                      onMapCreated: _onMapCreated,
                      onTap: (_) => showDetails(context),
                    ),
                  )
                : const Center(child: NoTrackPlaceholder()),
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
