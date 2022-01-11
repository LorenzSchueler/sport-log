import 'package:fixnum/fixnum.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/list_extension.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/secrets.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;
  final SessionsPageTab sessionsPageTab = SessionsPageTab.cardio;
  final String route = Routes.cardio.overview;
  final String defaultTitle = "Cardio Sessions";

  final List<CardioSession> _cardioSessions = [
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
    CardioSession(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        movementId: Int64(1),
        cardioType: CardioType.activeRecovery,
        datetime: DateTime.now(),
        distance: 5091,
        ascent: 8,
        descent: 7,
        time: 489,
        calories: null,
        track: null,
        avgCadence: 147,
        cadence: null,
        avgHeartRate: 169,
        heartRate: null,
        routeId: null,
        comments: "some comments here",
        deleted: false)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movement?.name ?? defaultTitle),
        actions: [
          IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.cardio.routeOverview),
              icon: const Icon(CustomIcons.route)),
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
        itemBuilder: (_, index) =>
            CardioSessionCard(cardioSession: _cardioSessions[index]),
        itemCount: _cardioSessions.length,
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
      floatingActionButton: ExpandableFab(
        icon: const Icon(Icons.add),
        items: [
          ExpandableFabItem(
            icon: const Icon(CustomIcons.stopwatch),
            onPressed: () => Navigator.of(context)
                .pushNamed(Routes.cardio.trackingSettings)
                .then(_handleNewCardioSession),
          ),
          ExpandableFabItem(
            icon: const Icon(Icons.notes_rounded),
            onPressed: () => Navigator.of(context)
                .pushNamed(Routes.cardio.cardioEdit)
                .then(_handleNewCardioSession),
          ),
        ],
      ),
    );
  }

  void _handleNewCardioSession(dynamic object) {
    if (object is ReturnObject<CardioSession>) {
      switch (object.action) {
        case ReturnAction.created:
          setState(() {
            _cardioSessions.add(object.payload);
            _cardioSessions.sortBy((c) => c.datetime);
          });
          break;
        case ReturnAction.updated:
          setState(() {
            _cardioSessions.update(object.payload, by: (o) => o.id);
            _cardioSessions.sortBy((c) => c.datetime);
          });
          break;
        case ReturnAction.deleted:
          setState(
              () => _cardioSessions.delete(object.payload, by: (c) => c.id));
      }
    } else {
      _logger.i("poped item is not a ReturnObject");
    }
  }
}

class CardioSessionCard extends StatelessWidget {
  final CardioSession cardioSession;

  const CardioSessionCard({Key? key, required this.cardioSession})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distance = cardioSession.distance == null
        ? '???'
        : (cardioSession.distance! / 1000).toStringAsFixed(3);
    final speed = cardioSession.distance == null || cardioSession.time == null
        ? '???'
        : ((cardioSession.distance! / 1000) / (cardioSession.time! / 3600))
            .toStringAsFixed(1);
    final duration = cardioSession.time == null
        ? "???"
        : formatTime(Duration(seconds: cardioSession.time!));

    late MapboxMapController _sessionMapController;

    return GestureDetector(
        onTap: () {
          Navigator.of(context)
              .pushNamed(Routes.cardio.cardioDetails, arguments: cardioSession);
        },
        child: Card(
          child: Column(children: [
            Defaults.sizedBox.vertical.small,
            Row(children: [
              Expanded(
                child: Text(
                  formatDatetime(cardioSession.datetime),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  "movement <${cardioSession.movementId}>", // TODO use movement name
                  textAlign: TextAlign.center,
                ),
              )
            ]),
            Defaults.sizedBox.vertical.small,
            cardioSession.track != null
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                        accessToken: Secrets.mapboxAccessToken,
                        styleString: Defaults.mapbox.style.outdoor,
                        initialCameraPosition: CameraPosition(
                          zoom: 13.0,
                          target: cardioSession.track!.first.latLng,
                        ),
                        onMapCreated: (MapboxMapController controller) =>
                            _sessionMapController = controller,
                        onStyleLoadedCallback: () {
                          _sessionMapController.addLine(LineOptions(
                              lineColor: "red",
                              geometry: cardioSession.track!
                                  .map((c) => c.latLng)
                                  .toList()));
                        },
                        onMapClick: (_, __) {
                          // TODO does not work
                          //_showDetails(context, cardioSession);
                        },
                        onMapLongClick: (_, __) {
                          //_showDetails(context, cardioSession);
                        }))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CustomIcons.route),
                      Text(" no track available"),
                    ],
                  ),
            Defaults.sizedBox.vertical.small,
            Row(children: [
              Expanded(
                child: ValueUnitDescription(
                  value: duration,
                  unit: null,
                  description: null,
                ),
              ),
              Expanded(
                child: ValueUnitDescription(
                  value: distance,
                  unit: "km",
                  description: null,
                ),
              ),
              Expanded(
                child: ValueUnitDescription(
                  value: speed,
                  unit: "km/h",
                  description: null,
                ),
              ),
            ]),
            Defaults.sizedBox.vertical.small,
          ]),
        ));
  }
}
