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
import 'package:fl_chart/fl_chart.dart';

class StrengthSessionsPage extends StatefulWidget {
  StrengthSessionsPage({
    Key? key,
    required this.start,
    required this.end,
    required this.movement,
  })  : assert((start == null) == (end == null)),
        _filterHash = Object.hash(start, end, movement?.id),
        super(key: key);

  final DateTime? start;
  final DateTime? end;
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

  static int byDate(
          StrengthSessionDescription ssd1, StrengthSessionDescription ssd2) =>
      ssd2.strengthSession.datetime.compareTo(ssd1.strengthSession.datetime);

  Future<void> update() async {
    _logger.d(
        'Updating strength sessions with start = ${widget.start}, end = ${widget.end}');
    _dataProvider
        .filterDescriptions(
            from: widget.start,
            until: widget.end,
            movementId: widget.movement?.id)
        .then((ssds) async {
      final now = DateTime.now();
      setState(() => _ssds = ssds);
      _logger.d('set state: ${DateTime.now().difference(now)}');
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
    _logger.d('build');
    return RefreshIndicator(
      onRefresh: _refreshPage,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.movement != null) _chart,
            _buildStrengthSessionList(context),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(StrengthSessionsPage oldWidget) {
    _logger.d('didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    if (widget.start != oldWidget.start ||
        widget.end != oldWidget.end ||
        widget.movement != oldWidget.movement) {
      update();
    }
  }

  Widget get _chart {
    assert(widget.movement != null);
    return LineChart(
      LineChartData(lineBarsData: [
        LineChartBarData(),
      ]),
    );
  }

  Widget _buildStrengthSessionList(BuildContext context) {
    if (_ssds.isEmpty) {
      return const Center(child: Text('No strength sessions there.'));
    }
    return Scrollbar(
      child: ListView.builder(
        itemBuilder: _strengthSessionBuilder,
        itemCount: _ssds.length,
        shrinkWrap: true,
      ),
    );
  }

  Widget _strengthSessionBuilder(BuildContext context, int index) {
    final ssd = _ssds[index];
    final String date =
        DateFormat('dd.MM.yyyy').format(ssd.strengthSession.datetime);
    final String time =
        DateFormat('HH:mm').format(ssd.strengthSession.datetime);
    final String? duration = ssd.strengthSession.interval == null
        ? null
        : formatDuration(Duration(seconds: ssd.strengthSession.interval!));
    final String subtitle =
        [date, time, if (duration != null) duration].join(' · ');

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
