import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/metcon/metcon_movement.dart';
import 'package:sport_log/models/metcon/metcon_movement_description.dart';
import 'package:sport_log/models/metcon/metcon_session.dart';
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

  late List<TimelineUnion> _items;
  @override
  void initState() {
    super.initState();

    var strengthSessions = [
      TimelineUnion.strengthSession(StrengthSessionWithStats(
          session: StrengthSession(
              id: randomId(),
              userId: UserState.instance.currentUser!.id,
              datetime: DateTime.now(),
              movementId: Int64(1),
              interval: const Duration(seconds: 120),
              comments: null,
              deleted: false),
          movement: Movement(
              id: randomId(),
              userId: UserState.instance.currentUser!.id,
              name: "My Movement",
              description: null,
              cardio: true,
              deleted: false,
              dimension: MovementDimension.reps),
          stats: StrengthSessionStats.fromStrengthSets(sets: [
            StrengthSet(
                id: randomId(),
                strengthSessionId: randomId(),
                setNumber: 1,
                count: 5,
                weight: 100,
                deleted: false)
          ], dateTime: DateTime.now()))),
    ];
    var metconSessions = [
      TimelineUnion.metconSession(MetconSessionDescription(
          metconSession: MetconSession(
              id: randomId(),
              userId: UserState.instance.currentUser!.id,
              metconId: Int64(1),
              datetime: DateTime.now(),
              time: 15 * 60,
              rounds: 3,
              reps: 0,
              rx: true,
              comments: "so comments are here",
              deleted: false),
          metconDescription: MetconDescription(
              metcon: Metcon(
                  id: randomId(),
                  userId: UserState.instance.currentUser!.id,
                  name: "cindy",
                  metconType: MetconType.amrap,
                  rounds: 3,
                  timecap: const Duration(minutes: 30),
                  description: "my description",
                  deleted: false),
              moves: [
                MetconMovementDescription(
                    metconMovement: MetconMovement(
                        id: randomId(),
                        metconId: Int64(1),
                        movementId: Int64(1),
                        movementNumber: 1,
                        count: 5,
                        weight: 0,
                        distanceUnit: null,
                        deleted: false),
                    movement: Movement(
                        id: randomId(),
                        userId: UserState.instance.currentUser!.id,
                        name: "pullup",
                        description: null,
                        cardio: false,
                        deleted: false,
                        dimension: MovementDimension.reps))
              ],
              hasReference: true)))
    ];
    var cardioSessions = [
      TimelineUnion.cardioSession(
        CardioSession(
            id: randomId(),
            userId: UserState.instance.currentUser!.id,
            movementId: Int64(1),
            cardioType: CardioType.training,
            datetime: DateTime.now().subtract(const Duration(days: 1)),
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
    ];
    var diaries = [
      TimelineUnion.diary(Diary(
          id: randomId(),
          userId: UserState.instance.currentUser!.id,
          date: DateTime.now().subtract(const Duration(days: 3)),
          bodyweight: 80.0,
          comments: "bla",
          deleted: false)),
    ];
    _items = strengthSessions;
    _items.addAll(cardioSessions);
    _items.addAll(metconSessions);
    _items.addAll(diaries);

    _items.sort((a, b) => b.compareTo(a));
  }

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
      body: ListView.builder(
        itemBuilder: _buildItemEntry,
        itemCount: _items.length,
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
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
        (cardioSession) => CardioSessionCard(cardioSession: cardioSession),
        (diary) => DiaryCard(diary: diary));
  }
}
