import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

import 'helpers.dart';
import 'series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class DayChart extends StatefulWidget {
  DayChart({
    Key? key,
    required this.series,
    required DateTime date,
    required this.movement,
  })  : date = date.beginningOfDay(),
        super(key: key);

  final SeriesType series;
  final DateTime date;
  final Movement movement;

  @override
  State<DayChart> createState() => _DayChartState();
}

class _DayChartState extends State<DayChart> {
  final _dataProvider = StrengthDataProvider();

  List<StrengthSessionDescription> _sessions = [];

  @override
  void initState() {
    super.initState();
    update();
  }

  void update() {
    _dataProvider
        .getSessionsWithStats(
      movementId: widget.movement.id,
      from: widget.date,
      until: widget.date.dayLater(),
      withSets: true,
    )
        .then((sessions) {
      if (mounted) {
        setState(() {
          _sessions = sessions;
        });
      }
    });
  }

  @override
  void didUpdateWidget(DayChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement ||
        oldWidget.date != widget.date) {
      update();
    }
  }

  List<BarChartGroupData> get _barData {
    final getValue = setAccessor(widget.series);
    final result = <BarChartGroupData>[];

    final color = primaryColorOf(context);

    var index = 0;
    for (final session in _sessions) {
      for (final set in session.strengthSets!) {
        result.add(BarChartGroupData(x: index++, barRods: [
          BarChartRodData(
            y: getValue(set),
            colors: [color],
          )
        ]));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final isTime = widget.movement.unit == MovementUnit.msecs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BarChart(BarChartData(
        barGroups: _barData,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: SideTitles(
            interval: null,
            showTitles: true,
            reservedSize: isTime ? 60 : 40,
            getTitles: isTime
                ? (value) =>
                    formatDurationShort(Duration(milliseconds: value.round()))
                : null,
          ),
          bottomTitles: SideTitles(showTitles: false),
          rightTitles: SideTitles(showTitles: false),
          topTitles: SideTitles(showTitles: false),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: gridLineDrawer(context),
          getDrawingVerticalLine: gridLineDrawer(context),
        ),
      )),
    );
  }
}
