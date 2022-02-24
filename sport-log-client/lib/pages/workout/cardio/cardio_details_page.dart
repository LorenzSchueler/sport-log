import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioDetailsPage extends StatefulWidget {
  final CardioSessionDescription cardioSessionDescription;

  const CardioDetailsPage({Key? key, required this.cardioSessionDescription})
      : super(key: key);

  @override
  State<CardioDetailsPage> createState() => CardioDetailsPageState();
}

class CardioDetailsPageState extends State<CardioDetailsPage> {
  final _logger = Logger('CardioDetailsPage');

  late MapboxMapController _mapController;

  @override
  Widget build(BuildContext context) {
    CardioSessionDescription cardioSessionDescription =
        widget.cardioSessionDescription;

    final distance = cardioSessionDescription.cardioSession.distance == null
        ? '???'
        : (cardioSessionDescription.cardioSession.distance! / 1000)
            .toStringAsFixed(3);
    final speed = cardioSessionDescription.cardioSession.distance == null ||
            cardioSessionDescription.cardioSession.time == null
        ? '???'
        : ((cardioSessionDescription.cardioSession.distance! / 1000) /
                (cardioSessionDescription.cardioSession.time!.inSeconds / 3600))
            .toStringAsFixed(1);
    final duration = cardioSessionDescription.cardioSession.time == null
        ? "???"
        : formatTime(cardioSessionDescription.cardioSession.time!);
    final calories = cardioSessionDescription.cardioSession.calories == null
        ? "-"
        : cardioSessionDescription.cardioSession.calories.toString();
    final avgCadence = cardioSessionDescription.cardioSession.avgCadence == null
        ? "-"
        : cardioSessionDescription.cardioSession.avgCadence.toString();
    final avgHeartRate =
        cardioSessionDescription.cardioSession.avgHeartRate == null
            ? "-"
            : cardioSessionDescription.cardioSession.avgHeartRate.toString();
    final ascent = cardioSessionDescription.cardioSession.ascent == null
        ? "-"
        : cardioSessionDescription.cardioSession.ascent.toString();
    final descent = cardioSessionDescription.cardioSession.descent == null
        ? "-"
        : cardioSessionDescription.cardioSession.descent.toString();

    TableRow rowSpacer = TableRow(children: [
      Defaults.sizedBox.vertical.normal,
      Defaults.sizedBox.vertical.normal,
    ]);

    return Scaffold(
        appBar: AppBar(
          title: RichText(
              text: TextSpan(children: [
            TextSpan(
              text: "${cardioSessionDescription.cardioSession.movementId} ",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: describeEnum(
                  cardioSessionDescription.cardioSession.cardioType),
              style: const TextStyle(fontSize: 14),
            )
          ])),
          actions: [
            IconButton(
                onPressed: () async {
                  final returnObj = await Navigator.pushNamed(
                      context, Routes.cardio.cardioEdit,
                      arguments: cardioSessionDescription);
                  if (returnObj is ReturnObject<CardioSessionDescription>) {
                    setState(() {
                      cardioSessionDescription = returnObj.payload;
                    });
                  }
                },
                icon: const Icon(AppIcons.edit))
          ],
        ),
        body: Stack(
          children: [
            Container(
                color: backgroundColorOf(context),
                child: Column(
                  children: [
                    cardioSessionDescription.cardioSession.track != null
                        ? Expanded(
                            child: MapboxMap(
                                accessToken: Defaults.mapbox.accessToken,
                                styleString: Defaults.mapbox.style.outdoor,
                                initialCameraPosition: CameraPosition(
                                  zoom: 14.0,
                                  target: cardioSessionDescription
                                                  .cardioSession.track ==
                                              null ||
                                          cardioSessionDescription
                                              .cardioSession.track!.isEmpty
                                      ? Defaults.mapbox.cameraPosition
                                      : cardioSessionDescription
                                          .cardioSession.track!.first.latLng,
                                ),
                                onMapCreated:
                                    (MapboxMapController controller) =>
                                        _mapController = controller,
                                onStyleLoadedCallback: () {
                                  if (cardioSessionDescription
                                          .cardioSession.track !=
                                      null) {
                                    _mapController.addLine(LineOptions(
                                        lineColor: "red",
                                        geometry: cardioSessionDescription
                                            .cardioSession.track!
                                            .map((c) => c.latLng)
                                            .toList()));
                                  }
                                  _mapController.addLine(LineOptions(
                                      lineColor: "blue",
                                      geometry: cardioSessionDescription
                                          .route?.track
                                          .map((route) => route.latLng)
                                          .toList()));
                                }))
                        : Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(AppIcons.route),
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
                    if (cardioSessionDescription.cardioSession.comments != null)
                      Text(cardioSessionDescription.cardioSession.comments!),
                    if (cardioSessionDescription.cardioSession.comments != null)
                      Defaults.sizedBox.vertical.normal,
                  ],
                )),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 5,
                ),
                child: Text(
                    formatDatetime(
                        cardioSessionDescription.cardioSession.datetime),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color:
                            cardioSessionDescription.cardioSession.track != null
                                ? backgroundColorOf(context)
                                : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
          ],
        ));
  }
}
