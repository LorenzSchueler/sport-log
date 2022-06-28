import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/timeline_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/timeline_union.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/diary/diary_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_overview_page.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_overview_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/overview_data_provider.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<TimelineUnion, TimelineRecords,
              TimelineDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: TimelineDataProvider(),
          entityAccessor: (dataProvider) =>
              (start, end, movement) => dataProvider.getByTimerange(
                    from: start,
                    until: end,
                  ),
          recordAccessor: (dataProvider) => () => dataProvider.getRecords(),
          loggerName: "TimelinePage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: const Text("Timeline"),
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
