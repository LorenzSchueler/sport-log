import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/widgets/input_fields/selection_bar.dart';

enum _SeriesType {
  sumDistance,
  sumDuration,
  avgSpeed,
  avgTempo,
  avgCadence,
  avgHeartRate;

  @override
  String toString() {
    switch (this) {
      case _SeriesType.sumDistance:
        return 'Sum Distance';
      case _SeriesType.sumDuration:
        return 'Sum Duration';
      case _SeriesType.avgSpeed:
        return 'Avg Speed';
      case _SeriesType.avgTempo:
        return 'Avg Tempo';
      case _SeriesType.avgCadence:
        return 'Avg Cadence';
      case _SeriesType.avgHeartRate:
        return 'Avg Heart Rate';
    }
  }

  double? value(CardioSession cardioSession) {
    switch (this) {
      case _SeriesType.sumDistance:
        final distance = cardioSession.distance;
        return distance == null ? null : distance / 1000;
      case _SeriesType.sumDuration:
        final seconds = cardioSession.time?.inSeconds;
        return seconds == null ? null : seconds / 3600;
      case _SeriesType.avgSpeed:
        return cardioSession.speed;
      case _SeriesType.avgTempo:
        final seconds = cardioSession.tempo?.inSeconds;
        return seconds == null ? null : seconds / 60;
      case _SeriesType.avgCadence:
        return cardioSession.avgCadence?.toDouble();
      case _SeriesType.avgHeartRate:
        return cardioSession.avgHeartRate?.toDouble();
    }
  }

  AggregatorType aggregator() {
    switch (this) {
      case _SeriesType.sumDistance:
        return AggregatorType.sum;
      case _SeriesType.sumDuration:
        return AggregatorType.sum;
      case _SeriesType.avgSpeed:
        return AggregatorType.avg;
      case _SeriesType.avgTempo:
        return AggregatorType.avg;
      case _SeriesType.avgCadence:
        return AggregatorType.avg;
      case _SeriesType.avgHeartRate:
        return AggregatorType.avg;
    }
  }

  bool isYFromZero() => [
        _SeriesType.sumDuration,
        _SeriesType.sumDistance,
        _SeriesType.avgSpeed,
        _SeriesType.avgTempo,
      ].contains(this);
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
            child: SelectionBar(
              onChange: (_SeriesType type) =>
                  setState(() => _selectedSeries = type),
              items: _SeriesType.values,
              getLabel: (_SeriesType type) => type.toString(),
              selectedItem: _selectedSeries,
            ),
          ),
        ),
        Defaults.sizedBox.vertical.small,
        DateTimeChart(
          chartValues: widget.cardioSessions
              .map((s) {
                final value = _selectedSeries.value(s);
                return value == null
                    ? null
                    : DateTimeChartValue(datetime: s.datetime, value: value);
              })
              .whereNotNull()
              .toList(),
          dateFilterState: widget.dateFilterState,
          yFromZero: _selectedSeries.isYFromZero(),
          aggregatorType: _selectedSeries.aggregator(),
        ),
      ],
    );
  }
}
