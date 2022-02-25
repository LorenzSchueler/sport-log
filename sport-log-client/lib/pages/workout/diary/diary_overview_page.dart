import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final _logger = Logger('DiaryPage');
  final _dataProvider = DiaryDataProvider.instance;
  List<Diary> _diaries = [];

  DateFilterState _dateFilter = MonthFilter.current();

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _dataProvider.onNoInternetConnection =
        () => showSimpleSnackBar(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    _dataProvider.onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d(
      'Updating diary page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final diaries =
        await _dataProvider.getByTimerange(_dateFilter.start, _dateFilter.end);
    setState(() => _diaries = diaries);
  }

  Future<void> _pullFromServer() async {
    await _dataProvider.pullFromServer().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onRefresh: _pullFromServer,
        child: _diaries.isEmpty
            ? SessionsPageTab.diary.noEntriesText
            : ListView.builder(
                itemBuilder: (_, index) => DiaryCard(diary: _diaries[index]),
                itemCount: _diaries.length,
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
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                diary.date.formatDate,
                style: const TextStyle(fontSize: 20),
              ),
              Defaults.sizedBox.horizontal.big,
              SizedBox(
                width: 80,
                child: diary.bodyweight != null
                    ? ValueUnitDescription(
                        value: diary.bodyweight!.toStringAsFixed(1),
                        unit: "kg",
                        description: null,
                      )
                    : null,
              ),
              Defaults.sizedBox.horizontal.big,
              Expanded(
                child: Text(
                  diary.comments ?? "",
                  textAlign: TextAlign.start,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
