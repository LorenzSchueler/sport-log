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
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
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
          OverviewDataProvider<TimelineUnion, TimelineRecords,
              TimelineDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: TimelineDataProvider(),
          entityAccessor: (dataProvider) =>
              (start, end, _, search) => dataProvider.getByTimerangeAndComment(
                    from: start,
                    until: end,
                    comment: search,
                  ),
          recordAccessor: (dataProvider) => () => dataProvider.getRecords(),
          loggerName: "TimelinePage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSearch
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (comment) => dataProvider.search = comment,
                    decoration: Theme.of(context).textFormFieldDecoration,
                  )
                : const Text("Timeline"),
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
                    ? SessionsPageTab.timeline.noEntriesWithoutAddText
                    : Container(
                        padding: Defaults.edgeInsets.normal,
                        child: ListView.separated(
                          itemBuilder: (context, index) => _itemCard(
                            dataProvider.entities[index],
                            dataProvider.records ?? TimelineRecords({}, {}),
                          ),
                          separatorBuilder: (_, __) =>
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
          drawer: MainDrawer(selectedRoute: Routes.timeline.overview),
          floatingActionButton: null,
        ),
      ),
    );
  }

  Widget _itemCard(TimelineUnion item, TimelineRecords timelineRecords) {
    return item.map(
      (strengthSession) => StrengthSessionCard(
        strengthSessionDescription: strengthSession,
        strengthRecords: timelineRecords.strengthRecords,
      ),
      (metconSessionDescription) => MetconSessionCard(
        metconSessionDescription: metconSessionDescription,
        metconRecords: timelineRecords.metconRecords,
      ),
      (cardioSession) =>
          CardioSessionCard(cardioSessionDescription: cardioSession),
      (diary) => DiaryCard(diary: diary),
    );
  }
}
