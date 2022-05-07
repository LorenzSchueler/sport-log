import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/helpers.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class AllChart extends StatefulWidget {
  const AllChart({
    Key? key,
    required this.series,
    required this.movement,
  }) : super(key: key);

  final SeriesType series;
  final Movement movement;

  @override
  State<AllChart> createState() => _AllChartState();
}

class _AllChartState extends State<AllChart> {
  final _dataProvider = StrengthSessionDescriptionDataProvider();

  List<StrengthSessionStats> _strengthSessionStats = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _update();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    super.dispose();
  }

  Future<void> _update() async {
    final strengthSessionStats = await _dataProvider
        .getStatsAggregationsByMonth(movementId: widget.movement.id);
    if (mounted) {
      setState(() => _strengthSessionStats = strengthSessionStats);
    }
  }

  @override
  void didUpdateWidget(AllChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement) {
      _update();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTime = widget.movement.dimension == MovementDimension.time;

    if (_strengthSessionStats.isEmpty) {
      return const CircularProgressIndicator();
    } else {
      final start = _strengthSessionStats.map((s) => s.datetime).min!;
      final end = _strengthSessionStats.map((s) => s.datetime).max!;
      final months = (end.difference(start).inDays / 30).round();
      final titleInterval = (months / 8).ceil();
      final List<int> markedMonths;
      if (titleInterval == 1) {
        markedMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      } else if (titleInterval == 2) {
        markedMonths = [1, 3, 5, 7, 9, 11];
      } else if (titleInterval == 3) {
        markedMonths = [1, 4, 7, 10];
      } else if (titleInterval == 4) {
        markedMonths = [1, 5, 9];
      } else if (titleInterval <= 6) {
        markedMonths = [1, 7];
      } else {
        markedMonths = [1];
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 5, 15, 0),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: _strengthSessionStats
                    .map(
                      (s) => FlSpot(
                        (s.datetime.difference(start).inDays + 1).toDouble(),
                        widget.series.statValue(s),
                      ),
                    )
                    .toList(),
                color: Theme.of(context).colorScheme.primary,
                dotData: FlDotData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final date = DateTime(start.year, 1, value.round());
                    return date.day == 15 && markedMonths.contains(date.month)
                        ? Text("${date.shortMonthName}\n${date.year}")
                        : const Text("");
                  },
                  reservedSize: 35,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: isTime ? 60 : 30,
                  getTitlesWidget: isTime
                      ? (value, _) => Text(
                            Duration(milliseconds: value.round())
                                .formatTimeWithMillis,
                          )
                      : null,
                ),
              ),
            ),
            minY: 0,
            maxY: _strengthSessionStats
                .map((s) => widget.series.statValue(s))
                .max
                .ceil()
                .toDouble(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              verticalInterval: 1,
              checkToShowVerticalLine: (value) {
                final datetime = DateTime(start.year, 1, value.round());
                return datetime.day == 1 &&
                        markedMonths.contains(datetime.month)
                    ? true
                    : false;
              },
              getDrawingVerticalLine: gridLineDrawer(context),
              getDrawingHorizontalLine: gridLineDrawer(context),
            ),
          ),
        ),
      );
    }
  }
}
