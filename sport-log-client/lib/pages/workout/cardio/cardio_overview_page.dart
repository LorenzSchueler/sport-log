import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/cardio/cardio_chart.dart';
import 'package:sport_log/pages/workout/cardio/no_track.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioOverviewPage extends StatelessWidget {
  CardioOverviewPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child:
          ProviderConsumer<
            OverviewDataProvider<
              CardioSessionDescription,
              void,
              CardioSessionDescriptionDataProvider,
              Movement
            >
          >(
            create: (_) => OverviewDataProvider(
              dataProvider: CardioSessionDescriptionDataProvider(),
              entityAccessor: (dataProvider) =>
                  (start, end, movement, search) =>
                      dataProvider.getByTimerangeAndMovementAndComment(
                        from: start,
                        until: end,
                        movement: movement,
                        comment: search,
                      ),
              recordAccessor: (_) => () async {},
              loggerName: "CardioSessionsPage",
            ),
            builder: (_, dataProvider, _) => Scaffold(
              appBar: AppBar(
                title: dataProvider.isSearch
                    ? TextFormField(
                        focusNode: _searchBar,
                        onChanged: (comment) => dataProvider.search = comment,
                      )
                    : Text(dataProvider.selected?.name ?? "Cardio Sessions"),
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
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).newBase(Routes.routeOverview),
                    icon: const Icon(AppIcons.route),
                  ),
                ],
                bottom: DateFilter(
                  initialState: dataProvider.dateFilter,
                  onFilterChanged: (dateFilter) =>
                      dataProvider.dateFilter = dateFilter,
                ),
              ),
              body: Stack(
                alignment: Alignment.topCenter,
                children: [
                  SyncRefreshIndicator(
                    child: dataProvider.entities.isEmpty
                        ? RefreshableNoEntriesText(
                            text: SessionsPageTab.cardio.noEntriesText,
                          )
                        : Padding(
                            padding: Defaults.edgeInsets.normal,
                            child: CustomScrollView(
                              slivers: [
                                SliverList.list(
                                  children: [
                                    if (dataProvider.isSelected)
                                      CardioChart(
                                        cardioSessions: dataProvider.entities
                                            .map((e) => e.cardioSession)
                                            .toList(),
                                        dateFilterState:
                                            dataProvider.dateFilter,
                                      ),
                                    CardioStatsCard(
                                      cardioSessionDescriptions:
                                          dataProvider.entities,
                                    ),
                                    Defaults.sizedBox.vertical.normal,
                                  ],
                                ),
                                SliverList.separated(
                                  itemBuilder: (_, index) => CardioSessionCard(
                                    cardioSessionDescription:
                                        dataProvider.entities[index],
                                    key: ValueKey(
                                      dataProvider
                                          .entities[index]
                                          .cardioSession
                                          .id,
                                    ),
                                    onSelected: (movement) =>
                                        dataProvider.selected = movement,
                                  ),
                                  separatorBuilder: (_, _) =>
                                      Defaults.sizedBox.vertical.normal,
                                  itemCount: dataProvider.entities.length,
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
              drawer: const MainDrawer(selectedRoute: Routes.cardioOverview),
              floatingActionButton: ExpandableFab(
                icon: const Icon(AppIcons.add),
                buttons: [
                  ActionButton(
                    icon: const Icon(AppIcons.stopwatch),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.trackingSettings,
                      arguments: dataProvider.selected,
                    ),
                  ),
                  ActionButton(
                    icon: const Icon(AppIcons.notes),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.cardioEdit,
                      arguments: dataProvider.selected,
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
  const CardioSessionCard({
    required this.cardioSessionDescription,
    required this.onSelected,
    super.key,
  });

  final CardioSessionDescription cardioSessionDescription;
  final void Function(Movement) onSelected;

  Future<void> _onMapCreated(MapController mapController) async {
    await mapController.setBoundsFromTracks(
      cardioSessionDescription.cardioSession.track,
      cardioSessionDescription.route?.track,
      padded: true,
    );
    if (cardioSessionDescription.route?.track != null) {
      await mapController.addRouteLine(cardioSessionDescription.route!.track!);
    }
    if (cardioSessionDescription.cardioSession.track != null) {
      await mapController.addTrackLine(
        cardioSessionDescription.cardioSession.track!,
      );
    }
  }

  void showDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.cardioDetails,
      arguments: cardioSessionDescription,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDetails(context),
      onLongPress: () => onSelected(cardioSessionDescription.movement),
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
                    cardioSessionDescription
                        .cardioSession
                        .datetime
                        .humanDateTime,
                  ),
                  Text(
                    cardioSessionDescription.movement.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
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
                      onMapCreated: _onMapCreated,
                      onTap: (_) => showDetails(context),
                    ),
                  )
                : const NoTrackPlaceholder(),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

class _MovementStat implements Comparable<_MovementStat> {
  _MovementStat.fromList(Movement movement, List<CardioSessionDescription> x)
    : name = movement.name,
      number = x.length,
      distance = x.map((s) => s.cardioSession.distance).nonNulls.sum,
      time = x.map((s) => s.cardioSession.time).nonNulls.sum;

  final String name;
  final int number;
  final int distance;
  final Duration time;

  @override
  int compareTo(_MovementStat other) {
    final comp = number.compareTo(other.number);
    if (comp != 0) {
      return comp;
    }
    return time.compareTo(other.time);
  }
}

class CardioStatsCard extends StatelessWidget {
  CardioStatsCard({
    required List<CardioSessionDescription> cardioSessionDescriptions,
    super.key,
  }) : _movementStats = groupBy(cardioSessionDescriptions, (c) => c.movement)
           .entries
           .map((e) => _MovementStat.fromList(e.key, e.value))
           .sorted((a, b) => -a.compareTo(b)); // reverse order

  final List<_MovementStat> _movementStats;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final stat = _movementStats[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.name, style: const TextStyle(fontSize: 20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ValueUnitDescription.timeSmall(stat.time),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        child: ValueUnitDescription.distanceSmall(
                          stat.distance,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${stat.number} times",
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          separatorBuilder: (_, _) => const Divider(),
          itemCount: _movementStats.length,
        ),
      ),
    );
  }
}
