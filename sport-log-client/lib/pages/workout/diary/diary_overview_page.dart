import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/pages/workout/charts/chart.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final _logger = Logger('DiaryPage');
  final _dataProvider = DiaryDataProvider();
  List<Diary> _diaries = [];

  DateFilterState _dateFilter = MonthFilter.current();

  @override
  void initState() {
    super.initState();
    _dataProvider
      ..addListener(_update)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider
      ..removeListener(_update)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d(
      'Updating diary page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final diaries = await _dataProvider.getByTimerange(
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    setState(() => _diaries = diaries);
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Diary"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: DateFilter(
              initialState: _dateFilter,
              onFilterChanged: (dateFilter) async {
                setState(() => _dateFilter = dateFilter);
                await _update();
              },
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _dataProvider.pullFromServer,
          child: _diaries.isEmpty
              ? SessionsPageTab.diary.noEntriesText
              : Container(
                  padding: Defaults.edgeInsets.normal,
                  child: Column(
                    children: [
                      if (_diaries.any((d) => d.bodyweight != null)) ...[
                        Chart(
                          chartValues: _diaries
                              .where((d) => d.bodyweight != null)
                              .map(
                                (s) => ChartValue(
                                  datetime: s.date,
                                  value: s.bodyweight ?? 0,
                                ),
                              )
                              .toList(),
                          desc: true,
                          dateFilterState: _dateFilter,
                          yFromZero: false,
                          aggregatorType: AggregatorType.avg,
                        ),
                        Defaults.sizedBox.vertical.normal,
                      ],
                      Expanded(
                        child: ListView.separated(
                          itemBuilder: (_, index) =>
                              DiaryCard(diary: _diaries[index]),
                          separatorBuilder: (_, __) =>
                              Defaults.sizedBox.vertical.normal,
                          itemCount: _diaries.length,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar:
            SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.diary),
        drawer: MainDrawer(selectedRoute: Routes.diary.overview),
        floatingActionButton: FloatingActionButton(
          child: const Icon(AppIcons.add),
          onPressed: () {
            Navigator.pushNamed(context, Routes.diary.edit);
          },
        ),
      ),
    );
  }
}

class DiaryCard extends StatelessWidget {
  final Diary diary;

  const DiaryCard({Key? key, required this.diary}) : super(key: key);

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
                  child: Text(
                    diary.comments!,
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
