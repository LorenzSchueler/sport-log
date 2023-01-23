import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class DiaryPage extends StatelessWidget {
  DiaryPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<Diary, void, DiaryDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: DiaryDataProvider(),
          entityAccessor: (dataProvider) =>
              (start, end, _, search) => dataProvider.getByTimerangeAndComment(
                    from: start,
                    until: end,
                    comment: search,
                  ),
          recordAccessor: (_) => () async {},
          loggerName: "DiaryPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSearch
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (comment) => dataProvider.search = comment,
                    decoration: Theme.of(context).textFormFieldDecoration,
                  )
                : const Text("Diary"),
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
                    ? SessionsPageTab.diary.noEntriesText
                    : Container(
                        padding: Defaults.edgeInsets.normal,
                        child: Column(
                          children: [
                            if (dataProvider.entities
                                .any((d) => d.bodyweight != null)) ...[
                              DateTimeChart(
                                chartValues: dataProvider.entities
                                    .map((s) {
                                      final value = s.bodyweight;
                                      return value == null
                                          ? null
                                          : DateTimeChartValue(
                                              datetime: s.date,
                                              value: value,
                                            );
                                    })
                                    .whereNotNull()
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
          drawer: const MainDrawer(selectedRoute: Routes.diaryOverview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, Routes.diaryEdit),
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
        Navigator.pushNamed(context, Routes.diaryEdit, arguments: diary);
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
