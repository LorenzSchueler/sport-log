import 'package:fixnum/fixnum.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/list_extension.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/ui_cubit.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');

  final List<CardioSession> _cardioSessions = [
    CardioSession(
        id: randomId(),
        userId: Int64(1),
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
        userId: Int64(1),
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
  void initState() {
    context.read<SessionsUiCubit>().showFab();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: ListView.builder(
      itemBuilder: _buildSessionCard,
      itemCount: _cardioSessions.length,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    ));
    ;
  }

  void showDetails(BuildContext context, CardioSession cardioSession) {
    Navigator.of(context)
        .pushNamed(Routes.cardio.cardio_details, arguments: cardioSession);
  }

  Widget _buildSessionCard(BuildContext buildContext, int index) {
    final CardioSession cardioSession = _cardioSessions[index];
    final distance = cardioSession.distance == null
        ? '???'
        : (cardioSession.distance! / 1000).toStringAsFixed(3);
    final speed = cardioSession.distance == null || cardioSession.time == null
        ? '???'
        : ((cardioSession.distance! / 1000) / (cardioSession.time! / 3600))
            .toStringAsFixed(1);
    final duration =
        cardioSession.time == null ? "???" : formatTime(cardioSession.time!);

    late MapboxMapController _sessionMapController;

    return GestureDetector(
        onTap: () {
          _logger.i("click");
          showDetails(context, cardioSession);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Defaults.borderRadius.normal,
            color: backgroundColorOf(context),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.only(bottom: 5),
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
                          _logger.i("map click");
                          showDetails(context, cardioSession);
                        },
                        onMapLongClick: (_, __) {
                          _logger.i("map long click");
                          showDetails(context, cardioSession);
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
          ]),
        ));
  }

  Widget? fab(BuildContext context) {
    _logger.d('FAB called!');

    return ExpandableFab(
      icon: const Icon(Icons.add),
      icons: const [
        Icon(CustomIcons.stopwatch),
        Icon(Icons.notes_rounded),
        Icon(CustomIcons.route),
      ],
      onPressed: [
        () => Navigator.of(context)
            .pushNamed(Routes.cardio.tracking_settings)
            .then(_handleNewCardioSession),
        () => Navigator.of(context).pushNamed(Routes.cardio.cardio_edit),
        () => Navigator.of(context).pushNamed(Routes.cardio.route_planning),
      ],
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
    }
  }
}
