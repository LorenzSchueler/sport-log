import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/diary/diary_chart.dart';
import 'package:sport_log/pages/workout/overview_card.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class DiaryOverviewPage extends StatelessWidget {
  DiaryOverviewPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child:
          ProviderConsumer<
            OverviewDataProvider<Diary, void, DiaryDataProvider, void>
          >(
            create: (_) => OverviewDataProvider(
              dataProvider: DiaryDataProvider(),
              entityAccessor: (dataProvider) =>
                  (start, end, _, search) =>
                      dataProvider.getByTimerangeAndComment(
                        from: start,
                        until: end,
                        comment: search,
                      ),
              recordAccessor: (_) => () async {},
              loggerName: "DiaryPage",
            ),
            builder: (_, dataProvider, _) => Scaffold(
              appBar: AppBar(
                title: dataProvider.isSearch
                    ? TextFormField(
                        focusNode: _searchBar,
                        onChanged: (comment) => dataProvider.search = comment,
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
                        ? RefreshableNoEntriesText(
                            text: SessionsPageTab.diary.noEntriesText,
                          )
                        : Padding(
                            padding: Defaults.edgeInsets.normal,
                            child: CustomScrollView(
                              slivers: [
                                if (dataProvider.dateFilter is! DayFilter &&
                                    dataProvider.entities.any(
                                      (d) => d.bodyweight != null,
                                    ))
                                  SliverList.list(
                                    children: [
                                      Defaults.sizedBox.vertical.normal,
                                      DiaryChart(
                                        diaries: dataProvider.entities,
                                        dateFilterState:
                                            dataProvider.dateFilter,
                                      ),
                                      Defaults.sizedBox.vertical.normal,
                                    ],
                                  ),
                                SliverList.separated(
                                  itemBuilder: (_, index) => DiaryCard(
                                    diary: dataProvider.entities[index],
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
    return OverviewCard(
      datetime: diary.date,
      left: const [],
      right: [
        if (diary.bodyweight != null)
          ValueUnitDescription(
            value: diary.bodyweight?.toStringAsFixed(1),
            unit: "kg Bodyweight",
            description: null,
          ),
      ],
      comments: diary.comments,
      onTap: () =>
          Navigator.pushNamed(context, Routes.diaryEdit, arguments: diary),
      onLongPress: null,
      dateOnly: true,
    );
  }
}
