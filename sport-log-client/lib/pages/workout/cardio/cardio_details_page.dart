import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioDetailsPage extends StatefulWidget {
  final CardioSession cardioSession;

  const CardioDetailsPage({Key? key, required this.cardioSession})
      : super(key: key);

  @override
  State<CardioDetailsPage> createState() => CardioDetailsPageState();
}

class CardioDetailsPageState extends State<CardioDetailsPage> {
  final _logger = Logger('CardioDetailsPage');

  final String _token = Secrets.mapboxAccessToken;

  late MapboxMapController _mapController;

  @override
  Widget build(BuildContext context) {
    final cardioSession = widget.cardioSession;
    final distance = cardioSession.distance == null
        ? '???'
        : (cardioSession.distance! / 1000).toStringAsFixed(3);
    final speed = cardioSession.distance == null || cardioSession.time == null
        ? '???'
        : ((cardioSession.distance! / 1000) / (cardioSession.time! / 3600))
            .toStringAsFixed(1);
    final duration =
        cardioSession.time == null ? "???" : formatTime(cardioSession.time!);
    final avgCadence = cardioSession.avgCadence == null
        ? "-"
        : cardioSession.avgCadence.toString();
    final ascent =
        cardioSession.ascent == null ? "-" : cardioSession.ascent.toString();
    final descent =
        cardioSession.descent == null ? "-" : cardioSession.descent.toString();

    TableRow rowSpacer = TableRow(children: [
      Defaults.sizedBox.vertical.normal,
      Defaults.sizedBox.vertical.normal,
    ]);

    return Scaffold(
        appBar: AppBar(
          title: const Text("Cardio Details"),
          actions: const [IconButton(onPressed: null, icon: Icon(Icons.edit))],
        ),
        body: Column(
          children: [
            Expanded(
                child: MapboxMap(
              accessToken: _token,
              styleString: Defaults.mapbox.style.outdoor,
              initialCameraPosition: const CameraPosition(
                zoom: 13.0,
                target: LatLng(47.27, 11.33),
              ),
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.TopRight,
              onMapCreated: (MapboxMapController controller) =>
                  _mapController = controller,
            )),
            Container(
                padding: const EdgeInsets.all(5),
                color: onPrimaryColorOf(context),
                child: Table(
                  children: [
                    rowSpacer,
                    TableRow(children: [
                      Expanded(
                        child: ValueUnitDescription(
                          value: distance,
                          unit: "km",
                          description: "Distance",
                          scale: 1.3,
                        ),
                      ),
                      Expanded(
                        child: ValueUnitDescription(
                          value: duration,
                          unit: null,
                          description: "Duration",
                          scale: 1.3,
                        ),
                      ),
                    ]),
                    rowSpacer,
                    TableRow(children: [
                      Expanded(
                        child: ValueUnitDescription(
                          value: speed,
                          unit: "km/h",
                          description: "Speed",
                          scale: 1.3,
                        ),
                      ),
                      Expanded(
                        child: ValueUnitDescription(
                          value: avgCadence,
                          unit: "bpm",
                          description: "Cadence",
                          scale: 1.3,
                        ),
                      ),
                    ]),
                    rowSpacer,
                    TableRow(children: [
                      Expanded(
                        child: ValueUnitDescription(
                          value: ascent,
                          unit: "m",
                          description: "Ascent",
                          scale: 1.3,
                        ),
                      ),
                      Expanded(
                        child: ValueUnitDescription(
                          value: descent,
                          unit: "m",
                          description: "Descent",
                          scale: 1.3,
                        ),
                      ),
                    ]),
                  ],
                )),
          ],
        ));
  }
}
