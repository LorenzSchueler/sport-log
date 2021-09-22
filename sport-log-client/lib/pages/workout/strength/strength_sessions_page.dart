import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/date_filter_state.dart';
import 'package:sport_log/pages/workout/strength/strength_chart.dart';

class StrengthSessionsPage extends StatefulWidget {
  StrengthSessionsPage({
    Key? key,
    required this.dateFilter,
    required this.movement,
  })  : _filterHash =
            Object.hash(dateFilter.start, dateFilter.end, movement?.id),
        super(key: key);

  final DateFilterState dateFilter;
  final Movement? movement;

  final int _filterHash;

  @override
  State<StrengthSessionsPage> createState() => _StrengthSessionsPageState();
}

class _StrengthSessionsPageState extends State<StrengthSessionsPage> {
  final _dataProvider = StrengthDataProvider();

  final _logger = Logger('StrengthSessionsPage');

  List<StrengthSessionDescription> _ssds = [];

  @override
  void initState() {
    super.initState();
    update();
  }

  Future<void> update() async {
    _logger.d(
        'Updating strength sessions with start = ${widget.dateFilter.start}, end = ${widget.dateFilter.end}');
    _dataProvider
        .getSessionsWithStats(
            from: widget.dateFilter.start,
            until: widget.dateFilter.end,
            movementId: widget.movement?.id)
        .then((ssds) async {
      setState(() => _ssds = ssds);
    });
  }

  // full update (from server)
  Future<void> _refreshPage() async {
    await _dataProvider.doFullUpdate().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
    update();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPage,
      child: _buildStrengthSessionList(context),
    );
  }

  @override
  void didUpdateWidget(StrengthSessionsPage oldWidget) {
    _logger.d('didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    if (widget.dateFilter != oldWidget.dateFilter ||
        widget.movement != oldWidget.movement) {
      update();
    }
  }

  Widget get _chart {
    if (widget.movement == null) {
      return const SizedBox.shrink();
    }
    return StrengthChart(
      dateFilter: widget.dateFilter,
      movement: widget.movement!,
      firstSessionDateTime: _ssds.first.strengthSession.datetime,
    );
    // if (widget.movement == null || widget.start == null || widget.end == null) {
    //   return const SizedBox();
    // }
    // final startMs = widget.start!.millisecondsSinceEpoch;
    // return Padding(
    //   padding: const EdgeInsets.symmetric(vertical: 12),
    //   child: AspectRatio(
    //     aspectRatio: 2,
    //     child: LineChart(LineChartData(
    //       borderData: FlBorderData(show: false),
    //       titlesData: FlTitlesData(
    //         topTitles: SideTitles(showTitles: false),
    //         rightTitles: SideTitles(showTitles: false),
    //         leftTitles: SideTitles(
    //           showTitles: true,
    //           reservedSize: 40,
    //           margin: -39,
    //         ),
    //         bottomTitles: SideTitles(
    //           showTitles: true,
    //           interval: Duration.millisecondsPerDay.toDouble(),
    //           checkToShowTitle: (a, b, c, d, value) {
    //             final datetime = DateTime.fromMillisecondsSinceEpoch(
    //                 value.toInt() + startMs);
    //             return datetime.day == 15;
    //           },
    //           getTitles: (ms) => shortMonthName(
    //               DateTime.fromMillisecondsSinceEpoch(ms.toInt() + startMs)
    //                   .month),
    //         ),
    //       ),
    //       lineBarsData: [
    //         LineChartBarData(
    //           colors: [primaryColorOf(context)],
    //           spots: _ssds
    //               .where((ssd) => ssd.stats!.maxEorm != null)
    //               .map((ssd) => FlSpot(
    //                   (ssd.strengthSession.datetime.millisecondsSinceEpoch -
    //                           startMs)
    //                       .toDouble(),
    //                   ssd.stats!.maxEorm!))
    //               .toList(),
    //           isCurved: false,
    //           dotData: FlDotData(show: false),
    //         ),
    //       ],
    //     )),
    //   ),
    // );
  }

  Widget _buildStrengthSessionList(BuildContext context) {
    if (_ssds.isEmpty) {
      return const Center(child: Text('No strength sessions there.'));
    }
    return Scrollbar(
      child: ListView.builder(
        itemBuilder: _strengthSessionBuilder,
        itemCount: _ssds.length + 1,
        shrinkWrap: true,
      ),
    );
  }

  Widget _strengthSessionBuilder(BuildContext context, int index) {
    if (index == 0) {
      assert(_ssds.isNotEmpty);
      return _chart;
    }
    index--;
    final ssd = _ssds[index];
    final String date =
        DateFormat('dd.MM.yyyy').format(ssd.strengthSession.datetime);
    final String time =
        DateFormat('HH:mm').format(ssd.strengthSession.datetime);
    final String? duration = ssd.strengthSession.interval == null
        ? null
        : formatDuration(Duration(seconds: ssd.strengthSession.interval!));
    final sets = ssd.stats!.numSets.toString() + ' sets';
    final String subtitle =
        [date, time, sets, if (duration != null) duration].join(' · ');

    final String title = ssd.movement.name;
    final String text =
        ssd.strengthSets?.map((ss) => ss.toDisplayName()).join(', ') ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ExpansionTileCard(
        // dirty fix for forcing an expansion tile card to be non-expanded at the start
        // (without it, an expanded card might show an everloading circular progress indicator)
        key: ValueKey(Object.hash(ssd.id, widget._filterHash)),
        leading: CircleAvatar(child: Text(ssd.movement.name[0])),
        title: Text(title),
        subtitle: Text(subtitle),
        children: [
          const Divider(),
          ssd.strengthSets == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(text),
                ),
          const Divider(),
          if (ssd.strengthSession.comments != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(ssd.strengthSession.comments!),
            ),
          if (ssd.strengthSession.comments != null) const Divider(),
          ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {}, // TODO
                icon: const Icon(Icons.delete),
              ),
              IconButton(
                onPressed: () {}, // TODO
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
        ],
        onExpansionChanged: (expanded) async {
          if (expanded && ssd.strengthSets == null) {
            ssd.strengthSets =
                await _dataProvider.getStrengthSetsByStrengthSession(ssd.id);
            setState(() {});
          }
        },
      ),
    );
  }
}
