import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/charts/duration_chart.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

class CardioDetailsPage extends StatefulWidget {
  const CardioDetailsPage({required this.cardioSessionDescription, super.key});

  final CardioSessionDescription cardioSessionDescription;

  @override
  State<CardioDetailsPage> createState() => _CardioDetailsPageState();
}

class _CardioDetailsPageState extends State<CardioDetailsPage> {
  late CardioSessionDescription _cardioSessionDescription;

  late MapboxMapController _mapController;
  Circle? _circle;
  double? _speed;
  int? _elevation;
  int? _heartRate;
  int? _cadence;

  static const _speedColor = Colors.blue;
  static const _elevationColor = Colors.white;
  static const _heartRateColor = Colors.orange;
  static const _cadenceColor = Colors.green;

  @override
  void initState() {
    _cardioSessionDescription = widget.cardioSessionDescription.clone();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "${_cardioSessionDescription.movement.name}  ",
                style: Theme.of(context).textTheme.headline6,
              ),
              TextSpan(
                text: describeEnum(
                  _cardioSessionDescription.cardioSession.cardioType,
                ),
              )
            ],
          ),
        ),
        actions: [
          if (_cardioSessionDescription.cardioSession.track != null &&
              _cardioSessionDescription.cardioSession.track!.isNotEmpty)
            IconButton(
              onPressed: _exportFile,
              icon: const Icon(AppIcons.download),
            ),
          IconButton(
            onPressed: () async {
              final returnObj = await Navigator.pushNamed(
                context,
                Routes.cardio.cardioEdit,
                arguments: _cardioSessionDescription,
              );
              if (returnObj is ReturnObject<CardioSessionDescription> &&
                  mounted) {
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _cardioSessionDescription.cardioSession.track != null
                    ? MapboxMap(
                        accessToken: Config.instance.accessToken,
                        styleString: MapboxStyles.OUTDOORS,
                        initialCameraPosition:
                            context.read<Settings>().lastMapPosition,
                        onMapCreated: (MapboxMapController controller) =>
                            _mapController = controller,
                        onStyleLoadedCallback: () {
                          _mapController.setBoundsFromTracks(
                            _cardioSessionDescription.cardioSession.track,
                            _cardioSessionDescription.route?.track,
                            padded: true,
                          );
                          if (_cardioSessionDescription.cardioSession.track !=
                              null) {
                            _mapController.addTrackLine(
                              _cardioSessionDescription.cardioSession.track!,
                            );
                          }
                          if (_cardioSessionDescription.route?.track != null) {
                            _mapController.addRouteLine(
                              _cardioSessionDescription.route!.track!,
                            );
                          }
                        },
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.route,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            Defaults.sizedBox.horizontal.normal,
                            const Text("no track available"),
                          ],
                        ),
                      ),
                Positioned(
                  top: 5,
                  left: 0,
                  right: 0,
                  child: Text(
                    _cardioSessionDescription.cardioSession.datetime
                        .toHumanDateTime(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          _cardioSessionDescription.cardioSession.track != null
                              ? Theme.of(context).colorScheme.background
                              : Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_cardioSessionDescription.cardioSession.track != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: const Color.fromARGB(120, 0, 0, 0),
                      child: Column(
                        children: [
                          if (_speed != null &&
                              _elevation != null &&
                              _heartRate != null &&
                              _cadence != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "${_speed} km/h",
                                  style: const TextStyle(color: _speedColor),
                                ),
                                Text(
                                  "${_elevation} m",
                                  style:
                                      const TextStyle(color: _elevationColor),
                                ),
                                Text(
                                  "${_heartRate} bpm",
                                  style:
                                      const TextStyle(color: _heartRateColor),
                                ),
                                Text(
                                  "${_cadence} rpm",
                                  style: const TextStyle(color: _cadenceColor),
                                ),
                              ],
                            ),
                          DurationChart(
                            chartLines: [
                              _speedLine(),
                              _elevationLine(),
                              _cadenceLine(),
                              _heartRateLine()
                            ],
                            yFromZero: true,
                            touchCallback: _touchCallback,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: Defaults.edgeInsets.normal,
            color: Theme.of(context).colorScheme.background,
            child: Column(
              children: [
                CardioValueUnitDescriptionTable(
                  cardioSessionDescription: _cardioSessionDescription,
                  currentDuration: null,
                ),
                if (_cardioSessionDescription.cardioSession.comments !=
                    null) ...[
                  Defaults.sizedBox.vertical.normal,
                  CommentsBox(
                    comments: _cardioSessionDescription.cardioSession.comments!,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  DurationChartLine _speedLine() => DurationChartLine.fromUngroupedChartValues(
        ungroupedChartValues: _cardioSessionDescription.cardioSession.track
                ?.groupListsBy(
                  (p) => Duration(minutes: p.time.inMinutes),
                )
                .entries
                .map((entry) {
              final km =
                  (entry.value.last.distance - entry.value.first.distance) /
                      1000;
              final hour = (entry.value.last.time - entry.value.first.time)
                      .inMilliseconds /
                  (1000 * 60 * 60);
              return DurationChartValue(
                duration: entry.key,
                value: km / hour,
              );
            }).toList() ??
            []
          ..sort(
            (v1, v2) => v1.duration.compareTo(v2.duration),
          ),
        lineColor: _speedColor,
      );

  DurationChartLine _elevationLine() =>
      DurationChartLine.fromUngroupedChartValues(
        ungroupedChartValues: _cardioSessionDescription.cardioSession.track
                ?.map(
                  (t) => DurationChartValue(
                    duration: t.time,
                    value: t.elevation,
                  ),
                )
                .toList() ??
            [],
        lineColor: _elevationColor,
      );

  DurationChartLine _heartRateLine() => DurationChartLine.fromDurationList(
        durations: _cardioSessionDescription.cardioSession.heartRate ?? [],
        lineColor: _heartRateColor,
      );

  DurationChartLine _cadenceLine() => DurationChartLine.fromDurationList(
        durations: _cardioSessionDescription.cardioSession.cadence ?? [],
        lineColor: _cadenceColor,
      );

  Future<void> _exportFile() async {
    final file = await saveTrackAsGpx(
      _cardioSessionDescription.cardioSession.track ?? [],
      startTime: _cardioSessionDescription.cardioSession.datetime,
    );
    if (file != null) {
      await showMessageDialog(
        context: context,
        text: 'Track exported to $file',
      );
    }
  }

  Future<void> _touchCallback(Duration? y) async {
    final pos = y != null
        ? _cardioSessionDescription.cardioSession.track?.reversed
            .firstWhereOrNull((pos) => pos.time <= y)
        : null;

    setState(() {
      double? speed = pos != null
          ? _cardioSessionDescription.cardioSession.currentSpeed(pos.time)
          : null;
      if (speed != null) {
        speed = (speed * 10).round() / 10;
      }
      _speed = speed;
      _elevation = pos?.elevation.round();
      _heartRate = pos != null
          ? _cardioSessionDescription.cardioSession.currentHeartRate(pos.time)
          : null;
      _cadence = pos != null
          ? _cardioSessionDescription.cardioSession.currentCadence(pos.time)
          : null;
    });

    _circle = await _mapController.updateLocationMarker(_circle, pos?.latLng);
  }
}
