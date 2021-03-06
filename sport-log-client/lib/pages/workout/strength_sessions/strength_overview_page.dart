import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/models/strength/strength_records.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_chart.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/overview_data_provider.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class StrengthSessionsPage extends StatelessWidget {
  const StrengthSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<StrengthSessionDescription, StrengthRecords,
              StrengthSessionDescriptionDataProvider, Movement>>(
        create: (_) => OverviewDataProvider(
          dataProvider: StrengthSessionDescriptionDataProvider(),
          entityAccessor: (dataProvider) =>
              (start, end, movement) => dataProvider.getByTimerangeAndMovement(
                    from: start,
                    until: end,
                    movement: movement,
                  ),
          recordAccessor: (dataProvider) =>
              () => dataProvider.getStrengthRecords(),
          loggerName: "StrengthSessionsPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: Text(dataProvider.selected?.name ?? "Strength Sessions"),
            actions: [
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
                    ? SessionsPageTab.strength.noEntriesText
                    : Container(
                        padding: Defaults.edgeInsets.normal,
                        child: Column(
                          children: [
                            if (dataProvider.isSelected) ...[
                              StrengthChart(
                                strengthSessionDescriptions:
                                    dataProvider.entities,
                                dateFilterState: dataProvider.dateFilter,
                              ),
                              Defaults.sizedBox.vertical.normal,
                              StrengthRecodsCard(
                                strengthRecords: dataProvider.records ?? {},
                                movement: dataProvider.selected!,
                              ),
                              Defaults.sizedBox.vertical.normal,
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemBuilder: (context, index) =>
                                    StrengthSessionCard(
                                  strengthSessionDescription:
                                      dataProvider.entities[index],
                                  strengthRecords: dataProvider.records ?? {},
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
            sessionsPageTab: SessionsPageTab.strength,
          ),
          drawer: MainDrawer(selectedRoute: Routes.strength.overview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, Routes.strength.edit),
          ),
        ),
      ),
    );
  }
}

class StrengthSessionCard extends StatelessWidget {
  StrengthSessionCard({
    required this.strengthSessionDescription,
    required this.strengthRecords,
    super.key,
  }) : strengthRecordTypes =
            strengthRecords.getCombinedRecordTypes(strengthSessionDescription);

  final StrengthSessionDescription strengthSessionDescription;
  final StrengthRecords strengthRecords;
  final List<StrengthRecordType> strengthRecordTypes;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.strength.details,
        arguments: strengthSessionDescription,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strengthSessionDescription.session.datetime
                          .toHumanDateTime(),
                    ),
                    Defaults.sizedBox.vertical.normal,
                    Text(
                      strengthSessionDescription.movement.name,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    if (strengthRecordTypes.isNotEmpty) ...[
                      Defaults.sizedBox.vertical.normal,
                      StrengthRecordMarkers(
                        strengthRecordTypes: strengthRecordTypes,
                      ),
                    ],
                    if (strengthSessionDescription.session.interval !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      Text(
                        "Interval: ${strengthSessionDescription.session.interval!.formatTimeShort}",
                      ),
                    ],
                    if (strengthSessionDescription.session.comments !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      CommentsBox(
                        comments: strengthSessionDescription.session.comments!,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: strengthSessionDescription.sets
                      .map(
                        (set) => Text(
                          set.toDisplayName(
                            strengthSessionDescription.movement.dimension,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StrengthRecodsCard extends StatelessWidget {
  StrengthRecodsCard({
    required this.movement,
    required StrengthRecords strengthRecords,
    super.key,
  }) : strengthRecord = strengthRecords[movement.id];

  final Movement movement;
  final StrengthRecord? strengthRecord;

  @override
  Widget build(BuildContext context) {
    String countText = "";
    if (strengthRecord != null) {
      switch (movement.dimension) {
        case MovementDimension.reps:
          countText = "${strengthRecord!.maxCount} reps";
          break;
        case MovementDimension.time:
          countText =
              Duration(milliseconds: strengthRecord!.maxCount).formatMsMill;
          break;
        case MovementDimension.distance:
          countText = '${strengthRecord!.maxCount} m';
          break;
        case MovementDimension.energy:
          countText = '${strengthRecord!.maxCount} cal';
          break;
      }
    }

    return strengthRecord == null
        ? Container()
        : Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (strengthRecord!.maxWeight != null) ...[
                    const Icon(
                      AppIcons.medal,
                      color: Colors.orange,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.small,
                    Text(
                      "${strengthRecord!.maxWeight!.round()} kg",
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ],
                  const Icon(
                    AppIcons.medal,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  Defaults.sizedBox.horizontal.small,
                  Text(
                    countText,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  if (strengthRecord!.maxEorm != null) ...[
                    Defaults.sizedBox.horizontal.normal,
                    const Icon(
                      AppIcons.medal,
                      color: Colors.grey,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.small,
                    Text(
                      "${strengthRecord!.maxEorm!.round()} kg",
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ],
              ),
            ),
          );
  }
}

class StrengthRecordMarkers extends StatelessWidget {
  const StrengthRecordMarkers({
    required this.strengthRecordTypes,
    super.key,
  });

  final List<StrengthRecordType> strengthRecordTypes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: strengthRecordTypes
          .map(
            (recordType) {
              switch (recordType) {
                case StrengthRecordType.maxWeight:
                  return [
                    const Icon(
                      AppIcons.medal,
                      color: Colors.orange,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ];
                case StrengthRecordType.maxCount:
                  return [
                    const Icon(
                      AppIcons.medal,
                      color: Colors.yellow,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ];
                case StrengthRecordType.maxEorm:
                  return [
                    const Icon(
                      AppIcons.medal,
                      color: Colors.grey,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ];
              }
            },
          )
          .toList()
          .flattened
          .toList(),
    );
  }
}
