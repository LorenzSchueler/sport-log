import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/cardio/cardio_chart.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/overview_data_provider.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioSessionsPage extends StatelessWidget {
  const CardioSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<CardioSessionDescription, void,
              CardioSessionDescriptionDataProvider, Movement>>(
        create: (_) => OverviewDataProvider(
          dataProvider: CardioSessionDescriptionDataProvider(),
          entityAccessor: (dataProvider) =>
              (start, end, movement) => dataProvider.getByTimerangeAndMovement(
                    from: start,
                    until: end,
                    movement: movement,
                  ),
          recordAccessor: (_) => () async {},
          loggerName: "CardioSessionsPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: Text(dataProvider.selected?.name ?? "Cardio Sessions"),
            actions: [
              IconButton(
                onPressed: () =>
                    Navigator.of(context).newBase(Routes.cardio.routeOverview),
                icon: const Icon(AppIcons.route),
              ),
              IconButton(
                // ignore: prefer-extracting-callbacks
                onPressed: () async {
                  final movement = await showMovementPicker(
                    context: context,
                    selectedMovement: dataProvider.selected,
                  );
                  if (movement == null) {
                    return;
                  } else if (movement.id == dataProvider.selected?.id) {
                    dataProvider.selected = null;
                  } else {
                    dataProvider.selected = movement;
                  }
                },
                icon: Icon(
                  dataProvider.isSelected
                      ? AppIcons.filterFilled
                      : AppIcons.filter,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: DateFilter(
                initialState: dataProvider.dateFilter,
                onFilterChanged: (dateFilter) =>
                    dataProvider.dateFilter = dateFilter,
              ),
            ),
          ),
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              RefreshIndicator(
                onRefresh: dataProvider.pullFromServer,
                child: dataProvider.entities.isEmpty
                    ? SessionsPageTab.cardio.noEntriesText
                    : Container(
                        padding: Defaults.edgeInsets.normal,
                        child: Column(
                          children: [
                            if (dataProvider.isSelected) ...[
                              CardioChart(
                                cardioSessions: dataProvider.entities
                                    .map((e) => e.cardioSession)
                                    .toList(),
                                dateFilterState: dataProvider.dateFilter,
                              ),
                              Defaults.sizedBox.vertical.normal,
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemBuilder: (_, index) => CardioSessionCard(
                                  cardioSessionDescription:
                                      dataProvider.entities[index],
                                  key: ValueKey(
                                    dataProvider
                                        .entities[index].cardioSession.id,
                                  ),
                                ),
                                separatorBuilder: (_, __) =>
                                    Defaults.sizedBox.vertical.normal,
                                itemCount: dataProvider.entities.length,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (dataProvider.isLoading)
                const Positioned(
                  top: 40,
                  child: RefreshProgressIndicator(),
                ),
            ],
          ),
          bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
            context: context,
            sessionsPageTab: SessionsPageTab.cardio,
          ),
          drawer: MainDrawer(selectedRoute: Routes.cardio.overview),
          floatingActionButton: ExpandableFab(
            icon: const Icon(AppIcons.add),
            buttons: [
              ActionButton(
                icon: const Icon(AppIcons.stopwatch),
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.cardio.trackingSettings,
                ),
              ),
              ActionButton(
                icon: const Icon(AppIcons.notes),
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.cardio.cardioEdit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardioSessionCard extends StatelessWidget {
  const CardioSessionCard({required this.cardioSessionDescription, super.key});

  final CardioSessionDescription cardioSessionDescription;

  void showDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.cardio.cardioDetails,
      arguments: cardioSessionDescription,
    );
  }

  Future<void> _setBoundsAndTracks(
    MapboxMapController sessionMapController,
  ) async {
    await sessionMapController.setBoundsFromTracks(
      cardioSessionDescription.cardioSession.track,
      cardioSessionDescription.route?.track,
      padded: true,
    );
    if (cardioSessionDescription.cardioSession.track != null) {
      await sessionMapController.addTrackLine(
        cardioSessionDescription.cardioSession.track!,
      );
    }
    if (cardioSessionDescription.route?.track != null) {
      await sessionMapController.addRouteLine(
        cardioSessionDescription.route!.track!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    late final MapboxMapController sessionMapController;

    return GestureDetector(
      onTap: () => showDetails(context),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cardioSessionDescription.cardioSession.datetime
                        .toHumanDateTime(),
                  ),
                  Text(
                    cardioSessionDescription.movement.name,
                    style: Theme.of(context).textTheme.subtitle1,
                  )
                ],
              ),
            ),
            cardioSessionDescription.cardioSession.track != null ||
                    cardioSessionDescription.route != null
                ? SizedBox(
                    height: 150,
                    child: StaticMapboxMap(
                      key: ObjectKey(
                        cardioSessionDescription,
                      ), // update on reload to get new track
                      onMapCreated: (MapboxMapController controller) =>
                          sessionMapController = controller,
                      onStyleLoadedCallback: () =>
                          _setBoundsAndTracks(sessionMapController),
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
                      Defaults.sizedBox.horizontal.normal,
                      const Text("no track available"),
                    ],
                  ),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueUnitDescription.timeSmall(
                        cardioSessionDescription.cardioSession.time,
                      ),
                      ValueUnitDescription.distanceSmall(
                        cardioSessionDescription.cardioSession.distance,
                      ),
                      ValueUnitDescription.speedSmall(
                        cardioSessionDescription.cardioSession.speed,
                      ),
                    ],
                  ),
                  if (cardioSessionDescription.cardioSession.comments !=
                      null) ...[
                    const Divider(),
                    CommentsBox(
                      comments:
                          cardioSessionDescription.cardioSession.comments!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
