import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sport_log/helpers/clock.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

/// needs to wrapped into something that constrains the size.
class AllChart extends DateTimePeriodChart {
  AllChart({
    required super.chartValues,
    required super.absolute,
    required super.formatter,
    super.key,
  }) : _startDateTime =
           chartValues.firstOrNull?.datetime.beginningOfDay() ??
           Clock.now().beginningOfYear(),
       _endDateTime =
           chartValues.lastOrNull?.datetime ?? Clock.now().endOfYear();

  final DateTime _startDateTime;
  final DateTime _endDateTime;

  bool get _isAtMostOneYear =>
      _endDateTime.difference(_startDateTime).inDays <= 366;

  String _tickLabel(double value) {
    final date = _startDateTime.add(Duration(days: value.round()));
    if (_isAtMostOneYear) {
      return date.day == 15 ? date.shortMonthName : "";
    }
    return date.month == 7 && date.day == 1 ? "${date.year}" : "";
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: chartValues
                .map(
                  (v) => FlSpot(
                    v.datetime.difference(_startDateTime).inDays + 1,
                    v.value,
                  ),
                )
                .toList(),
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: false),
          ),
        ],
        minY: minY,
        maxY: maxY,
        titlesData: titlesData(
          context,
          getBottomTitles: (value, _) => Text(_tickLabel(value)),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: gridLineDrawer(),
          verticalInterval: 1,
          checkToShowVerticalLine: (value) {
            final date = _startDateTime.add(Duration(days: value.round()));
            return date.day == 1 && (_isAtMostOneYear || date.month == 1);
          },
          getDrawingVerticalLine: gridLineDrawer(),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
