import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
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
  late CardioSessionDescription _cardioSessionDescription;

  @override
  void initState() {
    _cardioSessionDescription = widget.cardioSessionDescription;
    super.initState();
  }

  late MapboxMapController _mapController;

  @override
  Widget build(BuildContext context) {
    final distance = _cardioSessionDescription.cardioSession.distance == null
        ? '???'
        : (_cardioSessionDescription.cardioSession.distance! / 1000)
            .toStringAsFixed(3);
    final speed = _cardioSessionDescription.cardioSession.distance == null ||
            _cardioSessionDescription.cardioSession.time == null
        ? '???'
        : ((_cardioSessionDescription.cardioSession.distance! / 1000) /
                (_cardioSessionDescription.cardioSession.time!.inSeconds /
                    3600))
            .toStringAsFixed(1);
    final calories = _cardioSessionDescription.cardioSession.calories == null
        ? "-"
        : _cardioSessionDescription.cardioSession.calories.toString();
    final avgCadence =
        _cardioSessionDescription.cardioSession.avgCadence == null
            ? "-"
            : _cardioSessionDescription.cardioSession.avgCadence.toString();
    final avgHeartRate =
        _cardioSessionDescription.cardioSession.avgHeartRate == null
            ? "-"
            : _cardioSessionDescription.cardioSession.avgHeartRate.toString();
    final ascent = _cardioSessionDescription.cardioSession.ascent == null
        ? "-"
        : _cardioSessionDescription.cardioSession.ascent.toString();
    final descent = _cardioSessionDescription.cardioSession.descent == null
        ? "-"
        : _cardioSessionDescription.cardioSession.descent.toString();

    TableRow rowSpacer = TableRow(
      children: [
        Defaults.sizedBox.vertical.normal,
        Defaults.sizedBox.vertical.normal,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _cardioSessionDescription.movement.name + "  ",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: describeEnum(
                  _cardioSessionDescription.cardioSession.cardioType,
                ),
                style: const TextStyle(fontSize: 14),
              )
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final returnObj = await Navigator.pushNamed(
                context,
                Routes.cardio.cardioEdit,
                arguments: _cardioSessionDescription,
              );
              if (returnObj is ReturnObject<CardioSessionDescription>) {
                if (returnObj.action == ReturnAction.deleted) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _cardioSessionDescription = returnObj.payload;
                  });
                }
              }
            },
            icon: const Icon(AppIcons.edit),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).colorScheme.background,
            child: Column(
              children: [
                _cardioSessionDescription.cardioSession.track != null
                    ? Expanded(
                        child: MapboxMap(
                          accessToken: Defaults.mapbox.accessToken,
                          styleString: Defaults.mapbox.style.outdoor,
                          initialCameraPosition: Settings.lastMapPosition,
                          onMapCreated: (MapboxMapController controller) =>
                              _mapController = controller,
                          onStyleLoadedCallback: () {
                            final bounds = LatLngBoundsCombine.combinedBounds(
                              _cardioSessionDescription.cardioSession.track,
                              _cardioSessionDescription.route?.track,
                            );
                            if (bounds != null) {
                              _mapController.moveCamera(
                                CameraUpdate.newLatLngBounds(bounds),
                              );
                            }
                            if (_cardioSessionDescription.cardioSession.track !=
                                null) {
                              _mapController.addLine(
                                LineOptions(
                                  lineColor: Defaults.mapbox.trackLineColor,
                                  lineWidth: 2,
                                  geometry: _cardioSessionDescription
                                      .cardioSession.track!.latLngs,
                                ),
                              );
                            }
                            if (_cardioSessionDescription.route != null) {
                              _mapController.addLine(
                                LineOptions(
                                  lineColor: Defaults.mapbox.routeLineColor,
                                  lineWidth: 2,
                                  geometry: _cardioSessionDescription
                                      .route!.track.latLngs,
                                ),
                              );
                            }
                          },
                        ),
                      )
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
                    TableRow(
                      children: [
                        ValueUnitDescription(
                          value: distance,
                          unit: "km",
                          description: "Distance",
                          scale: 1.3,
                        ),
                        ValueUnitDescription(
                          value: _cardioSessionDescription
                                  .cardioSession.time?.formatTime ??
                              "",
                          unit: null,
                          description: "Duration",
                          scale: 1.3,
                        ),
                      ],
                    ),
                    rowSpacer,
                    TableRow(
                      children: [
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
                      ],
                    ),
                    rowSpacer,
                    TableRow(
                      children: [
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
                      ],
                    ),
                    rowSpacer,
                    TableRow(
                      children: [
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
                      ],
                    ),
                  ],
                ),
                Defaults.sizedBox.vertical.normal,
                if (_cardioSessionDescription.cardioSession.comments != null)
                  Text(_cardioSessionDescription.cardioSession.comments!),
                if (_cardioSessionDescription.cardioSession.comments != null)
                  Defaults.sizedBox.vertical.normal,
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 5,
            ),
            child: Text(
              _cardioSessionDescription.cardioSession.datetime.formatDatetime,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _cardioSessionDescription.cardioSession.track != null
                    ? Theme.of(context).colorScheme.background
                    : Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
