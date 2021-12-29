import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/movement_picker.dart';

class MetconSessionsPage extends StatefulWidget {
  const MetconSessionsPage({Key? key}) : super(key: key);

  @override
  State<MetconSessionsPage> createState() => MetconSessionsPageState();
}

class MetconSessionsPageState extends State<MetconSessionsPage> {
  final _logger = Logger('MetconSessionsPage');

  final List<MetconSessionDescription> _metconSessionDescriptions = [
    MetconSessionDescription(
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
                rounds: null,
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
            hasReference: true)),
    MetconSessionDescription(
        metconSession: MetconSession(
            id: randomId(),
            userId: UserState.instance.currentUser!.id,
            metconId: Int64(1),
            datetime: DateTime.now(),
            time: null,
            rounds: null,
            reps: null,
            rx: false,
            comments: "so comments are here",
            deleted: false),
        metconDescription: MetconDescription(
            metcon: Metcon(
                id: randomId(),
                userId: UserState.instance.currentUser!.id,
                name: null,
                metconType: MetconType.emom,
                rounds: 5,
                timecap: const Duration(minutes: 10),
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
                      weight: 10,
                      distanceUnit: null,
                      deleted: false),
                  movement: Movement(
                      id: randomId(),
                      userId: UserState.instance.currentUser!.id,
                      name: "pullup",
                      description: null,
                      cardio: false,
                      deleted: false,
                      dimension: MovementDimension.reps)),
              MetconMovementDescription(
                  metconMovement: MetconMovement(
                      id: randomId(),
                      metconId: Int64(1),
                      movementId: Int64(1),
                      movementNumber: 1,
                      count: 10,
                      weight: null,
                      distanceUnit: null,
                      deleted: false),
                  movement: Movement(
                      id: randomId(),
                      userId: UserState.instance.currentUser!.id,
                      name: "pushup",
                      description: null,
                      cardio: false,
                      deleted: false,
                      dimension: MovementDimension.reps))
            ],
            hasReference: true)),
    MetconSessionDescription(
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
                metconType: MetconType.forTime,
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
            hasReference: true)),
    MetconSessionDescription(
        metconSession: MetconSession(
            id: randomId(),
            userId: UserState.instance.currentUser!.id,
            metconId: Int64(1),
            datetime: DateTime.now(),
            time: null,
            rounds: 2,
            reps: 13,
            rx: true,
            comments: "so comments are here",
            deleted: false),
        metconDescription: MetconDescription(
            metcon: Metcon(
                id: randomId(),
                userId: UserState.instance.currentUser!.id,
                name: "cindy",
                metconType: MetconType.forTime,
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
            hasReference: true))
  ];

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;
  final SessionsPageTab sessionsPageTab = SessionsPageTab.metcon;
  final String route = Routes.metcon.sessionOverview;
  final String defaultTitle = "Metcon Sessions";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movement?.name ?? defaultTitle),
        actions: [
          IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.metcon.overview),
              icon: const Icon(CustomIcons.plan)),
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
      body: ListView.builder(
        itemBuilder: (_, index) => MetconSessionCard(
            metconSessionDescription: _metconSessionDescriptions[index]),
        itemCount: _metconSessionDescriptions.length,
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).pushNamed(Routes.metcon.sessionEdit);
          }),
    );
  }
}

class MetconSessionCard extends StatelessWidget {
  final MetconSessionDescription metconSessionDescription;

  const MetconSessionCard({Key? key, required this.metconSessionDescription})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(Routes.metcon.sessionEdit,
              arguments: metconSessionDescription);
        },
        child: Card(
            child: ListTile(
          leading: Icon(metconSessionDescription
              .metconDescription.metcon.metconType.icon),
          trailing: metconSessionDescription.metconSession.rx
              ? const Icon(Icons.check_circle_rounded)
              : null,
          title: Text(metconSessionDescription.name),
          subtitle: Text(metconSessionDescription.shortResultDescription),
          onTap: () => Navigator.of(context).pushNamed(
              Routes.metcon.sessionDetails,
              arguments: metconSessionDescription),
        )));
  }
}
