import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
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

  @override
  void initState() {
    context.read<SessionsUiCubit>().showFab();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            children: <Widget>[
          _buildSessionCard(),
          _buildSessionCard(),
          _buildSessionCard(),
          _buildSessionCard(),
          _buildSessionCard()
        ]));
    ;
  }

  Widget _buildSessionCard() {
    late MapboxMapController _sessionMapController;
    var _locations = const [
      LatLng(47.27, 11.33),
      LatLng(47.27, 11.331),
      LatLng(47.271, 11.33),
      LatLng(47.271, 11.331)
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(5),
      color: onPrimaryColorOf(context),
      child: Column(children: [
        SizedBox(
            height: 150,
            child: MapboxMap(
              accessToken: token,
              styleString: style,
              initialCameraPosition: const CameraPosition(
                zoom: 13.0,
                target: LatLng(47.27, 11.33),
              ),
              onMapCreated: (MapboxMapController controller) =>
                  _sessionMapController = controller,
              onStyleLoadedCallback: () => _sessionMapController
                  .addLine(LineOptions(lineColor: "red", geometry: _locations)),
            )),
        const SizedBox(
          height: 5,
        ),
        Row(children: [
          Expanded(
              child: Text(
            "1:41:53",
            textAlign: TextAlign.center,
          )),
          Expanded(
              child: Text(
            "18.54 km",
            textAlign: TextAlign.center,
          )),
          Expanded(
              child: Text(
            "11.3 km/h",
            textAlign: TextAlign.center,
          ))
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
        () => Navigator.of(context).pushNamed(Routes.cardio.tracking_settings),
        () => Navigator.of(context).pushNamed(Routes.cardio.data_input),
        () => Navigator.of(context).pushNamed(Routes.cardio.route_planning),
      ],
    );
  }
}
