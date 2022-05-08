import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/charts/all.dart';

class DiaryChart extends StatefulWidget {
  const DiaryChart({
    Key? key,
    required this.dateFilterState,
  }) : super(key: key);

  final DateFilterState dateFilterState;

  @override
  State<DiaryChart> createState() => _DiaryChartState();
}

class _DiaryChartState extends State<DiaryChart> {
  final _logger = Logger('DiaryChart');
  final _dataProvider = DiaryDataProvider();

  List<Diary> _diaries = [];
  late Type _dataFilterType;

  @override
  void initState() {
    super.initState();
    _dataFilterType = widget.dateFilterState.runtimeType;
    _logger.i("date filter: ${widget.dateFilterState.name}");
    _dataProvider.addListener(_update);
    _update();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    super.dispose();
  }

  @override
  void didUpdateWidget(DiaryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  Future<void> _update() async {
    final List<Diary> diaries;
    final Type dataFilterType;
    switch (widget.dateFilterState.runtimeType) {
      case DayFilter:
        diaries = await _dataProvider.getByTimerange(
          from: (widget.dateFilterState as DayFilter).start,
          until: (widget.dateFilterState as DayFilter).end,
        );
        dataFilterType = DayFilter;
        break;
      case WeekFilter:
        diaries = await _dataProvider.getByTimerange(
          from: (widget.dateFilterState as WeekFilter).start,
          until: (widget.dateFilterState as WeekFilter).end,
        );
        dataFilterType = WeekFilter;
        break;
      case MonthFilter:
        diaries = await _dataProvider.getByTimerange(
          from: (widget.dateFilterState as MonthFilter).start,
          until: (widget.dateFilterState as MonthFilter).end,
        );
        dataFilterType = MonthFilter;
        break;
      case YearFilter:
        diaries = await _dataProvider.getByTimerange(
          from: (widget.dateFilterState as YearFilter).start,
          until: (widget.dateFilterState as YearFilter).end,
        );
        dataFilterType = YearFilter;
        break;
      default:
        diaries = await _dataProvider.getNonDeleted();
        dataFilterType = NoFilter;
        break;
    }
    if (mounted) {
      setState(() {
        _diaries = diaries;
        _dataFilterType = dataFilterType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: _chart(),
    );
  }

  Widget _chart() {
    final chartValues = _diaries
        .map((s) => ChartValue(s.date, s.bodyweight ?? 0))
        .toList()
        .reversed // data must be ordered asc datetime
        .toList();
    // use _dataFilterType instead of widget.dateFilterState.runtimeType to keep data in sync with chart type even if update not yet computed
    switch (_dataFilterType) {
      case DayFilter:
        return DayChart(
          chartValues: chartValues,
          isTime: false,
        );
      case WeekFilter:
        return WeekChart(
          chartValues: chartValues,
          isTime: false,
        );
      case MonthFilter:
        return MonthChart(
          chartValues: chartValues,
          isTime: false,
        );
      case YearFilter:
        return YearChart(
          chartValues: chartValues,
          isTime: false,
        );
      default:
        return AllChart(
          chartValues: chartValues,
          isTime: false,
        );
    }
  }
}
