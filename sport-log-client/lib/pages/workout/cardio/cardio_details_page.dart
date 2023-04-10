import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
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
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/charts/duration_chart.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class _SimilarSessionAnnotation {
  _SimilarSessionAnnotation({
    required this.trackLine,
    required this.color,
    required this.touchMarker,
  });

  final PolylineAnnotation trackLine;
  final Color color;
  final NullablePointer<CircleAnnotation> touchMarker;
}

class CardioDetailsPage extends StatefulWidget {
  const CardioDetailsPage({required this.cardioSessionDescription, super.key});

  final CardioSessionDescription cardioSessionDescription;

  @override
  State<CardioDetailsPage> createState() => _CardioDetailsPageState();
}

class _CardioDetailsPageState extends State<CardioDetailsPage>
    with SingleTickerProviderStateMixin {
  final _dataProvider = CardioSessionDataProvider();

  late CardioSessionDescription _cardioSessionDescription =
      widget.cardioSessionDescription.clone();

  List<CardioSession>? _similarSessions;

  MapController? _mapController;
  late final TabController _tabController =
      TabController(length: 3, vsync: this)..addListener(() => setState(() {}));

  final NullablePointer<PolylineAnnotation> _trackLine =
      NullablePointer.nullPointer();
  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _touchMarker =
      NullablePointer.nullPointer();
  final Map<CardioSession, _SimilarSessionAnnotation>
      _similarSessionAnnotations = {};

  Duration? _time;
  double? _speed;
  int? _elevation;
  int? _heartRate;
  int? _cadence;

  late final _rateLimiter =
      RateLimiter(_touchCallback, const Duration(milliseconds: 200));

  static const _timeColor = Colors.white;
  static const _speedColor = Colors.blue;
  static const _elevationColor = Color.fromARGB(255, 170, 130, 100);
  static const _heartRateColor = Colors.red;
  static const _cadenceColor = Colors.green;

  static const _currentDurationOffset = Duration(minutes: 1);

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
          _similarSessions = null;
        });
        await _setBoundsAndLines();
      }
    }
  }

  Future<void> _findSimilarSessions() async {
    final similarSessions =
        await _dataProvider.getSimilarCardioSessions(_cardioSessionDescription);
    setState(() {
      _similarSessions = similarSessions;
    });
  }

  Future<void> _showSession(CardioSession session) async {
    final color =
        Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1);
    final line = await _mapController?.addLine(session.track!, color);
    if (line != null) {
      _similarSessionAnnotations.putIfAbsent(
        session,
        () => _SimilarSessionAnnotation(
          trackLine: line,
          color: color,
          touchMarker: NullablePointer.nullPointer(),
        ),
      );
      setState(() {});
    }
  }

  void _hideSession(CardioSession session) {
    final line = _similarSessionAnnotations.remove(session)!.trackLine;
    _mapController?.removeLine(line);
    setState(() {});
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
              child: _cardioSessionDescription.cardioSession.track != null &&
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
            ),
            if (fullscreen.isOff)
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: "Stats", icon: Icon(AppIcons.numberedList)),
                  Tab(text: "Chart", icon: Icon(AppIcons.chart)),
                  Tab(text: "Compare", icon: Icon(AppIcons.compare)),
                ],
              ),
            // TabBarView needs bounded height so different heights for tabs does not work
            if (fullscreen.isOff && _tabController.index == 0)
              Container(
                padding: Defaults.edgeInsets.normal,
                color: Theme.of(context).colorScheme.background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CardioValueUnitDescriptionTable(
                      cardioSessionDescription: _cardioSessionDescription,
                      currentDuration: null,
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
            if (fullscreen.isOff && _tabController.index == 1)
              SizedBox(
                height: 250,
                child: _cardioSessionDescription.cardioSession.track != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
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
                                  style: const TextStyle(color: _cadenceColor),
                                ),
                              // placeholder when no value is set
                              if (_time == null &&
                                  _speed == null &&
                                  _elevation == null &&
                                  _heartRate == null &&
                                  _cadence == null)
                                const Text("")
                            ],
                          ),
                          Expanded(
                            child: DurationChart(
                              chartLines: [
                                _speedLine(),
                                _elevationLine(),
                                _cadenceLine(),
                                _heartRateLine()
                              ],
                              yFromZero: true,
                              touchCallback: _rateLimiter.execute,
                            ),
                          ),
                        ],
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
              ),
            if (fullscreen.isOff && _tabController.index == 2)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: _similarSessions == null
                    ? ElevatedButton(
                        onPressed: _findSimilarSessions,
                        child: const Text("Find Similar Cardio Sessions"),
                      )
                    : _similarSessions!.isEmpty
                        ? Padding(
                            padding: Defaults.edgeInsets.normal,
                            child: const Text(
                              "No similar Cardio Sessions found.",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        : ListView.separated(
                            padding: Defaults.edgeInsets.normal,
                            shrinkWrap: true,
                            itemCount: _similarSessions!.length,
                            itemBuilder: (_, index) {
                              final session = _similarSessions![index];
                              return _SimilarCardioSessionCard(
                                session: session,
                                sessionAnnotation:
                                    _similarSessionAnnotations[session],
                                onShow: () => _showSession(session),
                                onHide: () => _hideSession(session),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                Defaults.sizedBox.vertical.normal,
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

  // ignore: long-method
  Future<void> _touchCallback(Duration? touchDuration) async {
    // needed because RateLimiter calls callback later
    if (!mounted) {
      return;
    }

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
            .currentSpeed(touchDuration - _currentDurationOffset, touchDuration)
            ?.roundToPrecision(1);
        _elevation = pos?.elevation.round();
        _heartRate = session.currentHeartRate(
          touchDuration - _currentDurationOffset,
          touchDuration,
        );
        _cadence = session.currentCadence(
          touchDuration - _currentDurationOffset,
          touchDuration,
        );
      });
      await _mapController?.updateLocationMarker(_touchMarker, pos?.latLng);
      for (final sessionTouchMarker in _similarSessionAnnotations.entries) {
        final session = sessionTouchMarker.key;
        final touchMarker = sessionTouchMarker.value.touchMarker;
        final Position? pos;
        if (session.track != null) {
          final index = binarySearchLargestLE(
            session.track!,
            (Position pos) => pos.time,
            touchDuration,
          );
          pos = index != null ? session.track![index] : null;
        } else {
          pos = null;
        }
        await _mapController?.updateLocationMarker(touchMarker, pos?.latLng);
      }
    } else {
      setState(() {
        _time = null;
        _speed = null;
        _elevation = null;
        _heartRate = null;
        _cadence = null;
      });
      await _mapController?.updateLocationMarker(_touchMarker, null);
      for (final sessionTouchMarker in _similarSessionAnnotations.entries) {
        final touchMarker = sessionTouchMarker.value.touchMarker;
        await _mapController?.updateLocationMarker(touchMarker, null);
      }
    }
  }
}

class _SimilarCardioSessionCard extends StatelessWidget {
  const _SimilarCardioSessionCard({
    required this.session,
    required this.sessionAnnotation,
    required this.onShow,
    required this.onHide,
  });

  final CardioSession session;
  final _SimilarSessionAnnotation? sessionAnnotation;
  final void Function() onShow;
  final void Function() onHide;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.datetime.toHumanDateTime(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueUnitDescription.timeSmall(session.time),
                      ValueUnitDescription.distanceSmall(session.distance),
                      ValueUnitDescription.speedSmall(session.speed),
                    ],
                  ),
                ],
              ),
            ),
            Defaults.sizedBox.horizontal.big,
            sessionAnnotation != null
                ? Icon(AppIcons.route, color: sessionAnnotation!.color)
                : const SizedBox(width: 24),
            sessionAnnotation == null
                ? IconButton(onPressed: onShow, icon: const Icon(AppIcons.add))
                : IconButton(
                    onPressed: onHide,
                    icon: const Icon(AppIcons.remove),
                  )
          ],
        ),
      ),
    );
  }
}
