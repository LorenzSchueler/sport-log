import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class DayChart extends StatelessWidget {
  const DayChart({
    required this.chartValues,
    required this.yFromZero,
    required this.isTime,
    Key? key,
  }) : super(key: key);

  final List<DateTimeChartValue> chartValues;
  final bool yFromZero;
  final bool isTime;

  @override
  Widget build(BuildContext context) {
    double minY = yFromZero
        ? 0.0
        : (chartValues.map((v) => v.value).minOrNull ?? 0).floor().toDouble();
    double maxY =
        (chartValues.map((v) => v.value).maxOrNull ?? 0).ceil().toDouble();
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: chartValues
                .mapIndexed(
                  (index, v) => FlSpot(
                    index + 1,
                    v.value,
                  ),
                )
                .toList(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
        minX: 1.0,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) => Text("Set ${value.round()}"),
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
        gridData: FlGridData(
          getDrawingHorizontalLine: gridLineDrawer(context),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
