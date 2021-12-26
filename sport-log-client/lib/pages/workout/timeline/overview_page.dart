import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/timeline_union.dart';
import 'package:sport_log/pages/workout/cardio/overview_page.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/diary/overview_page.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/movement_picker.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  State<TimelinePage> createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage> {
  final _logger = Logger('TimelinePage');

  final List<TimelineUnion> _items = [
    TimelineUnion.strengthSession(StrengthSession(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        datetime: DateTime.now(),
        movementId: Int64(1),
        interval: const Duration(seconds: 120),
        comments: null,
        deleted: false)),
    TimelineUnion.metconSession(MetconSession(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        metconId: Int64(1),
        datetime: DateTime.now(),
        time: 300,
        rounds: 3,
        reps: 0,
        rx: true,
        comments: null,
        deleted: false)),
    TimelineUnion.cardioSession(
      CardioSession(
          id: randomId(),
          userId: UserState.instance.currentUser!.id,
          movementId: Int64(1),
          cardioType: CardioType.training,
          datetime: DateTime.now(),
          distance: 15034,
          ascent: 308,
          descent: 297,
          time: 4189,
          calories: null,
          track: [
            Position(
                longitude: 11.33,
                latitude: 47.27,
                elevation: 600,
                distance: 0,
                time: 0),
            Position(
                longitude: 11.331,
                latitude: 47.27,
                elevation: 650,
                distance: 1000,
                time: 200),
            Position(
                longitude: 11.33,
                latitude: 47.272,
                elevation: 600,
                distance: 2000,
                time: 500)
          ],
          avgCadence: 167,
          cadence: null,
          avgHeartRate: 189,
          heartRate: null,
          routeId: null,
          comments: null,
          deleted: false),
    ),
    TimelineUnion.diary(Diary(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        date: DateTime.now().subtract(const Duration(days: 3)),
        bodyweight: 80.0,
        comments: "bla",
        deleted: false)),
  ];

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;
  final SessionsPageTab sessionsPageTab = SessionsPageTab.timeline;
  final String route = Routes.timeline.overview;
  final String defaultTitle = "Timeline";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movement?.name ?? defaultTitle),
        actions: [
          IconButton(
            onPressed: () async {
              final Movement? movement = await showMovementPickerDialog(context,
                  selectedMovement: _movement);
              if (movement == null) {
                return;
              } else if (movement.id == _movement?.id) {
                setState(() {
                  _movement = null;
                });
              } else {
                setState(() {
                  _movement = movement;
                });
              }
            },
            icon: Icon(_movement != null
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: DateFilter(
            initialState: _dateFilter,
            onFilterChanged: (dateFilter) => setState(() {
              _dateFilter = dateFilter;
            }),
          ),
        ),
      ),
      body: ListView.separated(
          itemBuilder: _buildItemEntry,
          itemCount: _items.length,
          separatorBuilder: (_, __) => const Divider()),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
      floatingActionButton: null,
    );
  }

  Widget _buildItemEntry(BuildContext context, int index) {
    final TimelineUnion item = _items[index];

    return GestureDetector(
        onTap: () {
          _showDetails(context, item);
        },
        child: _itemCard(context, item));
  }

  Widget _itemCard(BuildContext context, TimelineUnion item) {
    return item.map(
        (strengthSession) =>
            Text("StrengthSession: " + formatDate(strengthSession.datetime)),
        (metconSession) =>
            Text("MetconSession: " + formatDate(metconSession.datetime)),
        (cardioSession) =>
            CardioSessionsPageState.sessionCard(context, cardioSession),
        (diary) => DiaryPageState.itemCard(diary));
  }

  void _showDetails(BuildContext context, TimelineUnion item) {
    item.map(
        (strengthSession) => Navigator.of(context)
            .pushNamed(Routes.diary.edit, arguments: strengthSession),
        (metconSession) => Navigator.of(context)
            .pushNamed(Routes.metcon.edit, arguments: metconSession),
        (cardioSession) => Navigator.of(context)
            .pushNamed(Routes.cardio.cardioDetails, arguments: cardioSession),
        (diary) => Navigator.of(context)
            .pushNamed(Routes.diary.edit, arguments: diary));
    ;
  }
}
