import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/models/metcon/metcon_session_description.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/models/strength/strength_records.dart';
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
  const TimelinePage({Key? key}) : super(key: key);

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final _logger = Logger('TimelinePage');
  final _strengthDataProvider = StrengthSessionDescriptionDataProvider();
  final _metconDataProvider = MetconSessionDescriptionDataProvider();
  final _cardioDataProvider = CardioSessionDescriptionDataProvider();
  final _diaryDataProvider = DiaryDataProvider();
  List<StrengthSessionDescription> _strengthSessionsDescriptions = [];
  StrengthRecords _strengthRecords = {};
  List<MetconSessionDescription> _metconSessionsDescriptions = [];
  MetconRecords _metconRecords = {};
  List<CardioSessionDescription> _cardioSessionsDescriptions = [];
  List<Diary> _diaries = [];
  List<TimelineUnion> _items = [];
  bool _isLoading = false;

  DateFilterState _dateFilter = MonthFilter.current();

  @override
  void initState() {
    super.initState();
    _strengthDataProvider
      ..addListener(_updateStrengthSessions)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _metconDataProvider
      ..addListener(_updateMetconSessions)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _cardioDataProvider
      ..addListener(_updateCardioSessions)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _diaryDataProvider
      ..addListener(_updateDiaries)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _strengthDataProvider
      ..removeListener(_updateStrengthSessions)
      ..onNoInternetConnection = null;
    _metconDataProvider
      ..removeListener(_updateMetconSessions)
      ..onNoInternetConnection = null;
    _cardioDataProvider
      ..removeListener(_updateCardioSessions)
      ..onNoInternetConnection = null;
    _diaryDataProvider
      ..removeListener(_updateDiaries)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _updateStrengthSessions({bool isManual = false}) async {
    if (!isManual) {
      setState(() => _isLoading = true);
    }
    _strengthRecords = await _strengthDataProvider.getStrengthRecords();
    _strengthSessionsDescriptions =
        await _strengthDataProvider.getByTimerangeAndMovement(
      movement: null,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    sortItems();
    if (!isManual) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMetconSessions({bool isManual = false}) async {
    if (!isManual) {
      setState(() => _isLoading = true);
    }
    _metconRecords = await _metconDataProvider.getMetconRecords();
    _metconSessionsDescriptions =
        await _metconDataProvider.getByTimerangeAndMetcon(
      metcon: null,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    sortItems();
    if (!isManual) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCardioSessions({bool isManual = false}) async {
    if (!isManual) {
      setState(() => _isLoading = true);
    }
    _cardioSessionsDescriptions =
        await _cardioDataProvider.getByTimerangeAndMovement(
      movement: null,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    sortItems();
    if (!isManual) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDiaries({bool isManual = false}) async {
    if (!isManual) {
      setState(() => _isLoading = true);
    }
    _diaries = await _diaryDataProvider.getByTimerange(
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    sortItems();
    if (!isManual) {
      setState(() => _isLoading = false);
    }
  }

  void sortItems() {
    _items = _strengthSessionsDescriptions
        .map(TimelineUnion.strengthSession)
        .toList()
      ..addAll(_metconSessionsDescriptions.map(TimelineUnion.metconSession))
      ..addAll(_cardioSessionsDescriptions.map(TimelineUnion.cardioSession))
      ..addAll(_diaries.map(TimelineUnion.diary))
      ..sort((a, b) => b.compareTo(a));
  }

  Future<void> _update() async {
    setState(() => _isLoading = true);
    _logger.d(
      'Updating timeline with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    await _updateStrengthSessions(isManual: true);
    await _updateMetconSessions(isManual: true);
    await _updateCardioSessions(isManual: true);
    await _updateDiaries(isManual: true);
    setState(() => _isLoading = false);
    _logger.d("Updated timeline.");
  }

  Future<void> _pullFromServer() {
    return Future.wait([
      _strengthDataProvider.pullFromServer(),
      _metconDataProvider.pullFromServer(),
      _cardioDataProvider.pullFromServer(),
      _diaryDataProvider.pullFromServer(),
    ]);
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
              onRefresh: _pullFromServer,
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
        strengthRecords: _strengthRecords,
      ),
      (metconSessionDescription) => MetconSessionCard(
        metconSessionDescription: metconSessionDescription,
        metconRecords: _metconRecords,
      ),
      (cardioSession) =>
          CardioSessionCard(cardioSessionDescription: cardioSession),
      (diary) => DiaryCard(diary: diary),
    );
  }
}
