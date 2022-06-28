import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/overview_data_provider.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<Diary, void, DiaryDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: DiaryDataProvider(),
          entityAccessor: (dataProvider) => (start, end, _) =>
              dataProvider.getByTimerange(from: start, until: end),
          recordAccessor: (_) => () async {},
          loggerName: "DiaryPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: const Text("Diary"),
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
                    ? SessionsPageTab.diary.noEntriesText
                    : Container(
                        padding: Defaults.edgeInsets.normal,
                        child: Column(
                          children: [
                            if (dataProvider.entities
                                .any((d) => d.bodyweight != null)) ...[
                              DateTimeChart(
                                chartValues: dataProvider.entities
                                    .where((d) => d.bodyweight != null)
                                    .map(
                                      (s) => DateTimeChartValue(
                                        datetime: s.date,
                                        value: s.bodyweight ?? 0,
                                      ),
                                    )
                                    .toList(),
                                dateFilterState: dataProvider.dateFilter,
                                yFromZero: false,
                                aggregatorType: AggregatorType.avg,
                              ),
                              Defaults.sizedBox.vertical.normal,
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemBuilder: (_, index) => DiaryCard(
                                  diary: dataProvider.entities[index],
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
            sessionsPageTab: SessionsPageTab.diary,
          ),
          drawer: MainDrawer(selectedRoute: Routes.diary.overview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, Routes.diary.edit),
          ),
        ),
      ),
    );
  }
}

class DiaryCard extends StatelessWidget {
  const DiaryCard({required this.diary, super.key});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.diary.edit, arguments: diary);
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(diary.date.toHumanDay()),
                    if (diary.bodyweight != null) ...[
                      Defaults.sizedBox.vertical.normal,
                      ValueUnitDescription(
                        value: diary.bodyweight?.toStringAsFixed(1),
                        unit: "kg Bodyweight",
                        description: null,
                      ),
                    ]
                  ],
                ),
              ),
              if (diary.comments != null) ...[
                Defaults.sizedBox.horizontal.normal,
                Expanded(
                  child: CommentsBox(comments: diary.comments!),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
