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
import 'package:sport_log/widgets/expandable_fab.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');

  final String token = Secrets.mapboxAccessToken;
  final String style = 'mapbox://styles/mapbox/outdoors-v11';

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
        avgCadence: 147,
        cadence: null,
        avgHeartRate: 169,
        heartRate: null,
        routeId: null,
        comments: null,
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

    return Container(
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
        SizedBox(
            height: 150,
            child: MapboxMap(
              accessToken: token,
              styleString: style,
              initialCameraPosition: CameraPosition(
                zoom: 13.0,
                target: cardioSession.track?.first.latLng,
              ),
              onMapCreated: (MapboxMapController controller) =>
                  _sessionMapController = controller,
              onStyleLoadedCallback: () => _sessionMapController.addLine(
                  LineOptions(
                      lineColor: "red",
                      geometry:
                          cardioSession.track?.map((c) => c.latLng).toList())),
            )),
        Defaults.sizedBox.vertical.small,
        Row(children: [
          Expanded(
              child: Text(
            duration,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          )),
          Expanded(
              child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: "$distance ",
                style: const TextStyle(fontSize: 20),
              ),
              const TextSpan(
                text: "km",
                style: TextStyle(fontSize: 14),
              )
            ]),
            textAlign: TextAlign.center,
          )),
          Expanded(
              child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: "$speed ",
                style: const TextStyle(fontSize: 20),
              ),
              const TextSpan(
                text: "km/h",
                style: TextStyle(fontSize: 14),
              )
            ]),
            textAlign: TextAlign.center,
          )),
        ]),
      ]),
    );
  }

  Widget? fab(BuildContext context) {
    _logger.d('FAB called!');

    return ExpandableFab(
      icon: const Icon(Icons.add),
      icons: const [
        Icon(Icons.play_arrow_rounded),
        Icon(Icons.notes_rounded),
        Icon(Icons.map),
      ],
      onPressed: [
        () => Navigator.of(context)
            .pushNamed(Routes.cardio.tracking_settings)
            .then(_handleNewCardioSession),
        () => Navigator.of(context).pushNamed(Routes.cardio.data_input),
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
