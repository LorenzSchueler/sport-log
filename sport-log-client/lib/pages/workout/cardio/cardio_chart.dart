import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

enum _SeriesType {
  sumDistance(
    'Sum Distance',
    AggregatorType.sum,
    ChartValueFormatter.float,
    true,
  ), // m
  sumDuration(
    'Sum Duration',
    AggregatorType.sum,
    ChartValueFormatter.hms,
    true,
  ), // ms
  avgSpeed(
    'Avg Speed',
    AggregatorType.avg,
    ChartValueFormatter.float,
    true,
  ), // m/s
  avgTempo(
    'Avg Tempo',
    AggregatorType.avg,
    ChartValueFormatter.ms,
    true,
  ), // ms/km
  avgCadence(
    'Avg Cadence',
    AggregatorType.avg,
    ChartValueFormatter.float,
    false,
  ), // rpm
  avgHeartRate(
    'Avg Heart Rate',
    AggregatorType.avg,
    ChartValueFormatter.float,
    false,
  ); // bpm

  const _SeriesType(this.name, this.aggregator, this.formatter, this.yFromZero);

  final String name;
  final AggregatorType aggregator;
  final ChartValueFormatter formatter;
  final bool yFromZero;

  double? value(CardioSession cardioSession) {
    switch (this) {
      case _SeriesType.sumDistance:
        final distance = cardioSession.distance;
        return distance == null ? null : distance / 1000;
      case _SeriesType.sumDuration:
        return cardioSession.time?.inMilliseconds.toDouble();
      case _SeriesType.avgSpeed:
        return cardioSession.speed;
      case _SeriesType.avgTempo:
        return cardioSession.tempo?.inMilliseconds.toDouble();
      case _SeriesType.avgCadence:
        return cardioSession.avgCadence?.toDouble();
      case _SeriesType.avgHeartRate:
        return cardioSession.avgHeartRate?.toDouble();
    }
  }
}

class CardioChart extends StatefulWidget {
  const CardioChart({
    required this.cardioSessions,
    required this.dateFilterState,
    super.key,
  });

  final List<CardioSession> cardioSessions;
  final DateFilterState dateFilterState;

  @override
  State<CardioChart> createState() => _CardioChartState();
}

class _CardioChartState extends State<CardioChart> {
  _SeriesType _selectedSeries = _SeriesType.sumDistance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton(
              segments:
                  _SeriesType.values
                      .map(
                        (md) => ButtonSegment(value: md, label: Text(md.name)),
                      )
                      .toList(),
              selected: {_selectedSeries},
              showSelectedIcon: false,
              onSelectionChanged:
                  (selected) =>
                      setState(() => _selectedSeries = selected.first),
            ),
          ),
        ),
        Defaults.sizedBox.vertical.normal,
        DateTimeChart(
          chartValues:
              widget.cardioSessions
                  .map((s) {
                    final value = _selectedSeries.value(s);
                    return value == null
                        ? null
                        : DateTimeChartValue(
                          datetime: s.datetime,
                          value: value,
                        );
                  })
                  .nonNulls
                  .toList(),
          dateFilterState: widget.dateFilterState,
          absolute: _selectedSeries.yFromZero,
          formatter: _selectedSeries.formatter,
          aggregatorType: _selectedSeries.aggregator,
        ),
      ],
    );
  }
}
