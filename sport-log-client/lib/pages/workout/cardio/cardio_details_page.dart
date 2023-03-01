import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/double_extension.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/rate_limiter.dart';
import 'package:sport_log/helpers/search.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/charts/duration_chart.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CardioDetailsPage extends StatefulWidget {
  const CardioDetailsPage({required this.cardioSessionDescription, super.key});

  final CardioSessionDescription cardioSessionDescription;

  @override
  State<CardioDetailsPage> createState() => _CardioDetailsPageState();
}

class _CardioDetailsPageState extends State<CardioDetailsPage> {
  late CardioSessionDescription _cardioSessionDescription =
      widget.cardioSessionDescription.clone();

  MapController? _mapController;

  final NullablePointer<PolylineAnnotation> _trackLine =
      NullablePointer.nullPointer();
  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _touchMarker =
      NullablePointer.nullPointer();

  Duration? _time;
  double? _speed;
  int? _elevation;
  int? _heartRate;
  int? _cadence;

  late final _rateLimiter =
      RateLimiter(_touchCallback, const Duration(milliseconds: 200));

  static const _timeColor = Colors.white;
  static const _speedColor = Colors.blue;
  static const _elevationColor = Color.fromARGB(255, 180, 140, 120);
  static const _heartRateColor = Colors.orange;
  static const _cadenceColor = Colors.green;

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _setBoundsAndLines();
  }

  Future<void> _setBoundsAndLines() async {
    await _mapController?.setBoundsFromTracks(
      _cardioSessionDescription.cardioSession.track,
      _cardioSessionDescription.route?.track,
      padded: true,
    );
    await _mapController?.updateTrackLine(
      _trackLine,
      _cardioSessionDescription.cardioSession.track,
    );
    await _mapController?.updateRouteLine(
      _routeLine,
      _cardioSessionDescription.route?.track,
    );
  }

  Future<void> _pushEditPage() async {
    final returnObj = await Navigator.pushNamed(
      context,
      Routes.cardioEdit,
      arguments: _cardioSessionDescription,
    );
    if (returnObj is ReturnObject<CardioSessionDescription> && mounted) {
      if (returnObj.action == ReturnAction.deleted) {
        Navigator.pop(context);
      } else {
        setState(() {
          _cardioSessionDescription = returnObj.payload;
        });
        await _setBoundsAndLines();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cardioSessionDescription.movement.name),
        actions: [
          if (_cardioSessionDescription.cardioSession.track != null &&
              _cardioSessionDescription.cardioSession.track!.isNotEmpty)
            IconButton(
              onPressed: _exportFile,
              icon: const Icon(AppIcons.download),
            ),
          IconButton(
            onPressed: _pushEditPage,
            icon: const Icon(AppIcons.edit),
          )
        ],
      ),
      body: ProviderConsumer(
        create: (_) => BoolToggle.off(),
        builder: (context, fullscreen, _) => Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _cardioSessionDescription.cardioSession.track != null &&
                              _cardioSessionDescription
                                  .cardioSession.track!.isNotEmpty ||
                          _cardioSessionDescription.route?.track != null &&
                              _cardioSessionDescription.route!.track!.isNotEmpty
                      ? MapboxMapWrapper(
                          showScale: true,
                          showFullscreenButton: true,
                          showMapStylesButton: true,
                          showSelectRouteButton: false,
                          showSetNorthButton: true,
                          showCurrentLocationButton: false,
                          showCenterLocationButton: false,
                          scaleAtTop: fullscreen.isOff,
                          onFullscreenToggle: fullscreen.setState,
                          onMapCreated: _onMapCreated,
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
                  if (_cardioSessionDescription.cardioSession.track != null &&
                      fullscreen.isOff)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color.fromARGB(150, 0, 0, 0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (_time != null)
                                  Text(
                                    _time!.formatHms,
                                    style: const TextStyle(color: _timeColor),
                                  ),
                                if (_speed != null)
                                  Text(
                                    "$_speed km/h",
                                    style: const TextStyle(color: _speedColor),
                                  ),
                                if (_elevation != null)
                                  Text(
                                    "$_elevation m",
                                    style:
                                        const TextStyle(color: _elevationColor),
                                  ),
                                if (_heartRate != null)
                                  Text(
                                    "$_heartRate bpm",
                                    style:
                                        const TextStyle(color: _heartRateColor),
                                  ),
                                if (_cadence != null)
                                  Text(
                                    "$_cadence rpm",
                                    style:
                                        const TextStyle(color: _cadenceColor),
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
                              touchCallback: _rateLimiter.execute,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (fullscreen.isOff)
              Container(
                padding: Defaults.edgeInsets.normal,
                color: Theme.of(context).colorScheme.background,
                child: Column(
                  children: [
                    CardioValueUnitDescriptionTable(
                      cardioSessionDescription: _cardioSessionDescription,
                      currentDuration: null,
                      showDatetimeCardioType: true,
                    ),
                    if (_cardioSessionDescription.cardioSession.comments !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      CommentsBox(
                        comments:
                            _cardioSessionDescription.cardioSession.comments!,
                      ),
                    ]
                  ],
                ),
              ),
          ],
        ),
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
    if (mounted && file != null) {
      await showMessageDialog(
        context: context,
        text: 'Track exported to $file',
      );
    }
  }

  Future<void> _touchCallback(Duration? touchDuration) async {
    // needed because RateLimiter calls callback later
    if (!mounted) {
      return;
    }

    const currentDurationOffset = Duration(minutes: 1);

    if (touchDuration != null) {
      final session = _cardioSessionDescription.cardioSession;
      final track = session.track;

      final Position? pos;
      if (track != null) {
        final index = binarySearchLargestLE(
          track,
          (Position pos) => pos.time,
          touchDuration,
        );
        pos = index != null ? track[index] : null;
      } else {
        pos = null;
      }

      setState(() {
        _time = touchDuration;
        _speed = session
            .currentSpeed(touchDuration - currentDurationOffset, touchDuration)
            ?.roundToPrecision(1);
        _elevation = pos?.elevation.round();
        _heartRate = session.currentHeartRate(
          touchDuration - currentDurationOffset,
          touchDuration,
        );
        _cadence = session.currentCadence(
          touchDuration - currentDurationOffset,
          touchDuration,
        );
      });
      await _mapController?.updateLocationMarker(_touchMarker, pos?.latLng);
    } else {
      setState(() {
        _time = null;
        _speed = null;
        _elevation = null;
        _heartRate = null;
        _cadence = null;
      });
      await _mapController?.updateLocationMarker(_touchMarker, null);
    }
  }
}
