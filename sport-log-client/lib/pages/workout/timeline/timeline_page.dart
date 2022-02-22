import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/models/metcon/metcon_session_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
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

class TimelinePage extends StatefulWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  State<TimelinePage> createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage> {
  final _logger = Logger('TimelinePage');
  final _strengthDataProvider = StrengthSessionDescriptionDataProvider.instance;
  final _metconDataProvider = MetconDescriptionDataProvider.instance;
  //final _cardioDataProvider = CardioSessionDescriptionDataProvider.instance;
  final _diaryDataProvider = DiaryDataProvider.instance;
  List<StrengthSessionDescription> _strengthSessions = [];
  List<MetconSessionDescription> _metconSessions = [];
  List<CardioSessionDescription> _cardioSessions = [];
  List<Diary> _diaries = [];
  List<TimelineUnion> _items = [];

  //late List<TimelineUnion> _items;
  //@override
  //void initState() {
  //super.initState();

  //var strengthSessions = [
  //TimelineUnion.strengthSession(StrengthSessionWithSets(
  //session: StrengthSession(
  //id: randomId(),
  //userId: Settings.userId!,
  //datetime: DateTime.now(),
  //movementId: Int64(1),
  //interval: const Duration(seconds: 120),
  //comments: null,
  //deleted: false),
  //movement: Movement(
  //id: randomId(),
  //userId: Settings.userId!,
  //name: "My Movement",
  //description: null,
  //cardio: true,
  //deleted: false,
  //dimension: MovementDimension.reps),
  //stats: StrengthSessionStats.fromStrengthSets(sets: [
  //StrengthSet(
  //id: randomId(),
  //strengthSessionId: randomId(),
  //setNumber: 1,
  //count: 5,
  //weight: 100,
  //deleted: false)
  //], dateTime: DateTime.now()))),
  //];
  //var metconSessions = [
  //TimelineUnion.metconSession(MetconSessionDescription(
  //metconSession: MetconSession(
  //id: randomId(),
  //userId: Settings.userId!,
  //metconId: Int64(1),
  //datetime: DateTime.now(),
  //time: const Duration(minutes: 15),
  //rounds: 3,
  //reps: 0,
  //rx: true,
  //comments: "so comments are here",
  //deleted: false),
  //metconDescription: MetconDescription(
  //metcon: Metcon(
  //id: randomId(),
  //userId: Settings.userId!,
  //name: "cindy",
  //metconType: MetconType.amrap,
  //rounds: 3,
  //timecap: const Duration(minutes: 30),
  //description: "my description",
  //deleted: false),
  //moves: [
  //MetconMovementDescription(
  //metconMovement: MetconMovement(
  //id: randomId(),
  //metconId: Int64(1),
  //movementId: Int64(1),
  //movementNumber: 1,
  //count: 5,
  //weight: 0,
  //distanceUnit: null,
  //deleted: false),
  //movement: Movement(
  //id: randomId(),
  //userId: Settings.userId!,
  //name: "pullup",
  //description: null,
  //cardio: false,
  //deleted: false,
  //dimension: MovementDimension.reps))
  //],
  //hasReference: true)))
  //];
  //var cardioSessions = [
  //TimelineUnion.cardioSession(
  //CardioSession(
  //id: randomId(),
  //userId: Settings.userId!,
  //movementId: Int64(1),
  //cardioType: CardioType.training,
  //datetime: DateTime.now().subtract(const Duration(days: 1)),
  //distance: 15034,
  //ascent: 308,
  //descent: 297,
  //time: const Duration(seconds: 4189),
  //calories: null,
  //track: [
  //Position(
  //longitude: 11.33,
  //latitude: 47.27,
  //elevation: 600,
  //distance: 0,
  //time: const Duration(seconds: 0)),
  //Position(
  //longitude: 11.331,
  //latitude: 47.27,
  //elevation: 650,
  //distance: 1000,
  //time: const Duration(seconds: 200)),
  //Position(
  //longitude: 11.33,
  //latitude: 47.272,
  //elevation: 600,
  //distance: 2000,
  //time: const Duration(seconds: 500)),
  //],
  //avgCadence: 167,
  //cadence: null,
  //avgHeartRate: 189,
  //heartRate: null,
  //routeId: null,
  //comments: null,
  //deleted: false),
  //),
  //];
  //var diaries = [
  //TimelineUnion.diary(Diary(
  //id: randomId(),
  //userId: Settings.userId!,
  //date: DateTime.now().subtract(const Duration(days: 3)),
  //bodyweight: 80.0,
  //comments: "bla",
  //deleted: false)),
  //];
  //_items = strengthSessions;
  //_items.addAll(cardioSessions);
  //_items.addAll(metconSessions);
  //_items.addAll(diaries);

  //_items.sort((a, b) => b.compareTo(a));
  //}

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;

  @override
  void initState() {
    super.initState();
    _strengthDataProvider.addListener(updateStrengthSessions);
    _strengthDataProvider.onNoInternetConnection =
        () => showSimpleSnackBar(context, 'No Internet connection.');
    _metconDataProvider.addListener(updateMetconSessions);
    _metconDataProvider.onNoInternetConnection =
        () => showSimpleSnackBar(context, 'No Internet connection.');
    // _cardioDataProvider.addListener(updateCardioSessions());
    // _cardioDataProvider.onNoInternetConnection =
    () => showSimpleSnackBar(context, 'No Internet connection.');
    _diaryDataProvider.addListener(updateDiaries);
    _diaryDataProvider.onNoInternetConnection =
        () => showSimpleSnackBar(context, 'No Internet connection.');
    update();
  }

  @override
  void dispose() {
    _strengthDataProvider.removeListener(updateStrengthSessions);
    _strengthDataProvider.onNoInternetConnection = null;
    _metconDataProvider.removeListener(updateMetconSessions);
    _metconDataProvider.onNoInternetConnection = null;
    //_cardioDataProvider.removeListener(updateCardioSessions());
    //_cardioDataProvider.onNoInternetConnection = null;
    _diaryDataProvider.removeListener(updateDiaries);
    _diaryDataProvider.onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> updateStrengthSessions() async {
    _strengthSessions = await _strengthDataProvider.getByTimerangeAndMovement(
        movementId: null, from: _dateFilter.start, until: _dateFilter.end);
    sortItems();
  }

  Future<void> updateMetconSessions() async {
    //_metconSessions = await _metconDataProvider.getByTimerange(
    //_dateFilter.start, _dateFilter.end);
    sortItems();
  }

  Future<void> updateCardioSessions() async {
    //_cardioSessions = await _cardioDataProvider.getByTimerange(
    //_dateFilter.start, _dateFilter.end);
    sortItems();
  }

  Future<void> updateDiaries() async {
    _diaries = await _diaryDataProvider.getByTimerange(
        _dateFilter.start, _dateFilter.end);
    sortItems();
  }

  void sortItems() {
    final items =
        _strengthSessions.map((s) => TimelineUnion.strengthSession(s)).toList();
    items.addAll(_metconSessions.map((m) => TimelineUnion.metconSession(m)));
    items.addAll(_cardioSessions.map((c) => TimelineUnion.cardioSession(c)));
    items.addAll(_diaries.map((d) => TimelineUnion.diary(d)));
    items.sort((a, b) => b.compareTo(a));
    setState(() => _items = items);
  }

  Future<void> update() async {
    _logger.d(
        'Updating timeline with start = ${_dateFilter.start}, end = ${_dateFilter.end}');
    await updateStrengthSessions();
    await updateMetconSessions();
    await updateCardioSessions();
    await updateDiaries();
  }

  // full update (from server)
  Future<void> _refreshPage() async {
    await _diaryDataProvider.pullFromServer().onError((error, stackTrace) {
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
        title: Text(_movement?.name ?? "Timeline"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: DateFilter(
            initialState: _dateFilter,
            onFilterChanged: (dateFilter) async {
              setState(() => _dateFilter = dateFilter);
              update();
            },
          ),
        ),
      ),
      body: RefreshIndicator(
          onRefresh: _refreshPage,
          child: ListView.builder(
            itemBuilder: _buildItemEntry,
            itemCount: _items.length,
          )),
      bottomNavigationBar: SessionTabUtils.bottomNavigationBar(
          context, SessionsPageTab.timeline),
      drawer: MainDrawer(selectedRoute: Routes.timeline.overview),
      floatingActionButton: null,
    );
  }

  Widget _buildItemEntry(BuildContext context, int index) {
    final TimelineUnion item = _items[index];

    return _itemCard(context, item);
  }

  Widget _itemCard(BuildContext context, TimelineUnion item) {
    return item.map(
        (strengthSession) =>
            StrengthSessionCard(strengthSessionWithStats: strengthSession),
        (metconSessionDescription) => MetconSessionCard(
            metconSessionDescription: metconSessionDescription),
        (cardioSession) =>
            CardioSessionCard(cardioSessionDescription: cardioSession),
        (diary) => DiaryCard(diary: diary));
  }
}
