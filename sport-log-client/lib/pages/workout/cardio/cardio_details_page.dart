import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
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

  late MapboxMapController _mapController;

  @override
  Widget build(BuildContext context) {
    CardioSession cardioSession = widget.cardioSession;

    final distance = cardioSession.distance == null
        ? '???'
        : (cardioSession.distance! / 1000).toStringAsFixed(3);
    final speed = cardioSession.distance == null || cardioSession.time == null
        ? '???'
        : ((cardioSession.distance! / 1000) / (cardioSession.time! / 3600))
            .toStringAsFixed(1);
    final duration =
        cardioSession.time == null ? "???" : formatTime(cardioSession.time!);
    final calories = cardioSession.calories == null
        ? "-"
        : cardioSession.calories.toString();
    final avgCadence = cardioSession.avgCadence == null
        ? "-"
        : cardioSession.avgCadence.toString();
    final avgHeartRate = cardioSession.avgHeartRate == null
        ? "-"
        : cardioSession.avgHeartRate.toString();
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
          title: RichText(
              text: TextSpan(children: [
            TextSpan(
              text: "${cardioSession.movementId} ",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: describeEnum(cardioSession.cardioType),
              style: const TextStyle(fontSize: 14),
            )
          ])),
          actions: [
            IconButton(
                onPressed: () => Navigator.of(context)
                        .pushNamed(Routes.cardio.cardio_edit,
                            arguments: cardioSession)
                        .then((value) {
                      setState(() {
                        cardioSession = value as CardioSession;
                      });
                    }),
                icon: const Icon(Icons.edit))
          ],
        ),
        body: Stack(
          children: [
            Container(
                color: backgroundColorOf(context),
                child: Column(
                  children: [
                    cardioSession.track != null
                        ? Expanded(
                            child: MapboxMap(
                                accessToken: Secrets.mapboxAccessToken,
                                styleString: Defaults.mapbox.style.outdoor,
                                initialCameraPosition: CameraPosition(
                                  zoom: 14.0,
                                  target: cardioSession.track!.first.latLng,
                                ),
                                onMapCreated:
                                    (MapboxMapController controller) =>
                                        _mapController = controller,
                                onStyleLoadedCallback: () {
                                  if (cardioSession.track != null) {
                                    _mapController.addLine(LineOptions(
                                        lineColor: "red",
                                        geometry: cardioSession.track!
                                            .map((c) => c.latLng)
                                            .toList()));
                                  }
                                  // TODO also show route if available
                                  // _mapController.addLine(LineOptions(
                                  // lineColor: "blue",
                                  // geometry: cardioSession.routeId
                                  // ?.map((c) => c.latLng)
                                  // .toList()));
                                }))
                        : Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(CustomIcons.route),
                                Text(" no track available"),
                              ],
                            ),
                          ),
                    Defaults.sizedBox.vertical.normal,
                    Table(
                      children: [
                        TableRow(children: [
                          ValueUnitDescription(
                            value: distance,
                            unit: "km",
                            description: "Distance",
                            scale: 1.3,
                          ),
                          ValueUnitDescription(
                            value: duration,
                            unit: null,
                            description: "Duration",
                            scale: 1.3,
                          ),
                        ]),
                        rowSpacer,
                        TableRow(children: [
                          ValueUnitDescription(
                            value: speed,
                            unit: "km/h",
                            description: "Speed",
                            scale: 1.3,
                          ),
                          ValueUnitDescription(
                            value: calories,
                            unit: "cal",
                            description: "Energy",
                            scale: 1.3,
                          ),
                        ]),
                        rowSpacer,
                        TableRow(children: [
                          ValueUnitDescription(
                            value: ascent,
                            unit: "m",
                            description: "Ascent",
                            scale: 1.3,
                          ),
                          ValueUnitDescription(
                            value: descent,
                            unit: "m",
                            description: "Descent",
                            scale: 1.3,
                          ),
                        ]),
                        rowSpacer,
                        TableRow(children: [
                          ValueUnitDescription(
                            value: avgCadence,
                            unit: "rpm",
                            description: "Cadence",
                            scale: 1.3,
                          ),
                          ValueUnitDescription(
                            value: avgHeartRate,
                            unit: "bpm",
                            description: "Heart Rate",
                            scale: 1.3,
                          ),
                        ]),
                      ],
                    ),
                    Defaults.sizedBox.vertical.normal,
                    if (cardioSession.comments != null)
                      Text(cardioSession.comments!),
                    if (cardioSession.comments != null)
                      Defaults.sizedBox.vertical.normal,
                  ],
                )),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 5,
                ),
                child: Text(formatDatetime(cardioSession.datetime),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cardioSession.track != null
                            ? backgroundColorOf(context)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
          ],
        ));
  }
}
