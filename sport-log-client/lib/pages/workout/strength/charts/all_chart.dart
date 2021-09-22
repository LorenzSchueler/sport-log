import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';

import 'series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class AllChart extends StatefulWidget {
  const AllChart({
    Key? key,
    required this.series,
    required this.movement,
    /// only needed for year and month
    required this.firstDateTime,
  }) : super(key: key);

  final DateTime firstDateTime; // TODO: can this be done more elegantly?
  final SeriesType series;
  final Movement movement;

  @override
  State<AllChart> createState() => _AllChartState();
}

class _AllChartState extends State<AllChart> {
  final _dataProvider = StrengthDataProvider();

  List<StrengthSessionStats> _stats = [];

  @override
  void initState() {
    super.initState();
    update();
  }

  void update() {
    _dataProvider.getStatsByMonth(movementId: widget.movement.id).then((stats) {
      setState(() {
        _stats = stats;
      });
    });
  }

  @override
  void didUpdateWidget(AllChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement) {
      update();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container();
  }
}
