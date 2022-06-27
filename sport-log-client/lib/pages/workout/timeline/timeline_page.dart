import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/timeline_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/timeline_union.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/diary/diary_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_overview_page.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_overview_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final _logger = Logger('TimelinePage');
  final _dataProvider = TimelineDataProvider();
  TimelineRecords _records = TimelineRecords({}, {});
  List<TimelineUnion> _items = [];
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
    _logger.d(
      'Updating timeline with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    _items = await _dataProvider.getByTimerange(
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    _records = await _dataProvider.getRecords();
    setState(() => _isLoading = false);
    _logger.d("Updated timeline.");
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Timeline"),
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
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            RefreshIndicator(
              onRefresh: _dataProvider.pullFromServer,
              child: _items.isEmpty
                  ? SessionsPageTab.timeline.noEntriesWithoutAddText
                  : Container(
                      padding: Defaults.edgeInsets.normal,
                      child: ListView.separated(
                        itemBuilder: (context, index) =>
                            _itemCard(_items[index]),
                        separatorBuilder: (_, __) =>
                            Defaults.sizedBox.vertical.normal,
                        itemCount: _items.length,
                      ),
                    ),
            ),
            if (_isLoading)
              const Positioned(
                top: 40,
                child: RefreshProgressIndicator(),
              ),
          ],
        ),
        bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
          context,
          SessionsPageTab.timeline,
        ),
        drawer: MainDrawer(selectedRoute: Routes.timeline.overview),
        floatingActionButton: null,
      ),
    );
  }

  Widget _itemCard(TimelineUnion item) {
    return item.map(
      (strengthSession) => StrengthSessionCard(
        strengthSessionDescription: strengthSession,
        strengthRecords: _records.strengthRecords,
      ),
      (metconSessionDescription) => MetconSessionCard(
        metconSessionDescription: metconSessionDescription,
        metconRecords: _records.metconRecords,
      ),
      (cardioSession) =>
          CardioSessionCard(cardioSessionDescription: cardioSession),
      (diary) => DiaryCard(diary: diary),
    );
  }
}
