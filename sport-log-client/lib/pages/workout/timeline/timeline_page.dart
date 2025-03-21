import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/timeline_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/timeline_union.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter.dart';
import 'package:sport_log/pages/workout/diary/diary_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_overview_page.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_overview_page.dart';
import 'package:sport_log/pages/workout/wod/wod_overview_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

class TimelinePage extends StatelessWidget {
  TimelinePage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
        OverviewDataProvider<
          TimelineUnion,
          TimelineRecords,
          TimelineDataProvider,
          MovementOrMetcon
        >
      >(
        create:
            (_) => OverviewDataProvider(
              dataProvider: TimelineDataProvider(),
              entityAccessor:
                  (dataProvider) =>
                      (start, end, movementOrMetcon, search) => dataProvider
                          .getByTimerangeAndMovementOrMetconAndComment(
                            from: start,
                            until: end,
                            comment: search,
                            movementOrMetcon: movementOrMetcon,
                          ),
              recordAccessor: (dataProvider) => () => dataProvider.getRecords(),
              loggerName: "TimelinePage",
            ),
        builder:
            (_, dataProvider, __) => Scaffold(
              appBar: AppBar(
                title:
                    dataProvider.isSearch
                        ? TextFormField(
                          focusNode: _searchBar,
                          onChanged: (comment) => dataProvider.search = comment,
                        )
                        : Text(dataProvider.selected?.name ?? "Timeline"),
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
                      final movementOrMetcon = await showMovementOrMetconPicker(
                        context: context,
                        selectedMovementOrMetcon: dataProvider.selected,
                      );
                      if (movementOrMetcon == null) {
                        return;
                      } else if (movementOrMetcon == dataProvider.selected) {
                        dataProvider.selected = null;
                      } else {
                        dataProvider.selected = movementOrMetcon;
                      }
                    },
                    icon: Icon(
                      dataProvider.isSelected
                          ? AppIcons.filterFilled
                          : AppIcons.filter,
                    ),
                  ),
                ],
                bottom: DateFilter(
                  initialState: dataProvider.dateFilter,
                  onFilterChanged:
                      (dateFilter) => dataProvider.dateFilter = dateFilter,
                ),
              ),
              body: Stack(
                alignment: Alignment.topCenter,
                children: [
                  SyncRefreshIndicator(
                    child:
                        dataProvider.entities.isEmpty
                            ? RefreshableNoEntriesText(
                              text:
                                  SessionsPageTab
                                      .timeline
                                      .noEntriesWithoutAddText,
                            )
                            : Padding(
                              padding: Defaults.edgeInsets.normal,
                              child: ListView.separated(
                                itemBuilder:
                                    (context, index) => _itemCard(
                                      dataProvider.entities[index],
                                      dataProvider.records ??
                                          TimelineRecords({}, {}),
                                      (movementOrMetcon) =>
                                          dataProvider.selected =
                                              movementOrMetcon,
                                    ),
                                separatorBuilder:
                                    (_, __) =>
                                        Defaults.sizedBox.vertical.normal,
                                itemCount: dataProvider.entities.length,
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
                sessionsPageTab: SessionsPageTab.timeline,
              ),
              drawer: const MainDrawer(selectedRoute: Routes.timelineOverview),
            ),
      ),
    );
  }

  Widget _itemCard(
    TimelineUnion item,
    TimelineRecords timelineRecords,
    void Function(MovementOrMetcon) onSelected,
  ) {
    return item.map(
      (strengthSession) => StrengthSessionCard(
        strengthSessionDescription: strengthSession,
        strengthRecords: timelineRecords.strengthRecords,
        onSelected:
            (movement) => onSelected(MovementOrMetcon.movement(movement)),
      ),
      (metconSessionDescription) => MetconSessionCard(
        metconSessionDescription: metconSessionDescription,
        metconRecords: timelineRecords.metconRecords,
        onSelected: (metcon) => onSelected(MovementOrMetcon.metcon(metcon)),
      ),
      (cardioSession) => CardioSessionCard(
        cardioSessionDescription: cardioSession,
        onSelected:
            (movement) => onSelected(MovementOrMetcon.movement(movement)),
      ),
      (wod) => WodCard(wod: wod),
      (diary) => DiaryCard(diary: diary),
    );
  }
}
