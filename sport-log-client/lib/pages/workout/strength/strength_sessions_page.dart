import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:intl/intl.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/human_readable.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/state/local_state.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionsPage extends StatefulWidget {
  const StrengthSessionsPage({
    Key? key,
    required this.start,
    required this.end,
  })  : assert(
            (start != null && end != null) || (start == null && end == null)),
        super(key: key);

  final DateTime? start;
  final DateTime? end;

  @override
  State<StrengthSessionsPage> createState() => _StrengthSessionsPageState();
}

class _StrengthSessionsPageState extends State<StrengthSessionsPage> {
  final _dataProvider = StrengthDataProvider();
  LocalState<StrengthSessionDescription> _state = LocalState.empty();
  final _logger = Logger('StrengthSessionsPage');

  @override
  void initState() {
    super.initState();
    update();
  }

  void update() async {
    _logger.d(
        'Updating strength sessions with start = ${widget.start}, end = ${widget.end}');
    _dataProvider
        .filterDescriptions(from: widget.start, until: widget.end)
        .then((ssds) {
      setState(() => _state = LocalState.fromList(ssds));
    });
  }

  void _handlePageReturn(dynamic object) {
    if (object is ReturnObject<StrengthSessionDescription>) {
      switch (object.action) {
        case ReturnAction.created:
          setState(() => _state.create(object.object));
          break;
        case ReturnAction.updated:
          setState(() => _state.update(object.object));
          break;
        case ReturnAction.deleted:
          setState(() => _state.delete(object.object.id));
      }
    }
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
      child: _buildStrengthSessionList(context),
    );
  }

  @override
  void didUpdateWidget(StrengthSessionsPage oldWidget) {
    _logger.d('didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    if (widget.start != oldWidget.start || widget.end != oldWidget.end) {
      update();
    }
  }

  Widget _buildStrengthSessionList(BuildContext context) {
    if (_state.isEmpty) {
      return const Center(child: Text('No strength sessions there.'));
    }
    return Scrollbar(
      child: ImplicitlyAnimatedList(
        items: _state.sortedBy((o1, o2) =>
            -o1.strengthSession.datetime.compareTo(o2.strengthSession.datetime)),
        itemBuilder: _buildStrengthSession,
        areItemsTheSame: StrengthSessionDescription.areTheSame,
      ),
    );
  }

  Widget _buildStrengthSession(BuildContext context,
      Animation<double> animation, StrengthSessionDescription ssd, int i) {
    final String date =
        DateFormat('dd.MM.yyyy').format(ssd.strengthSession.datetime);
    final String time =
        DateFormat('HH:mm').format(ssd.strengthSession.datetime);
    final String sets = '${ssd.numberOfSets} sets';
    final String? duration = ssd.strengthSession.interval == null
        ? null
        : formatDuration(Duration(seconds: ssd.strengthSession.interval!));
    final String subtitle =
        [date, time, sets, if (duration != null) duration].join(' · ');

    final String title = ssd.movement.name;
    final String text =
        ssd.strengthSets?.map((ss) => ss.toDisplayName()).join(', ') ?? '';

    return SizeFadeTransition(
      key: ValueKey(ssd.strengthSession.id),
      animation: animation,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: ExpansionTileCard(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      ),
    );
  }
}
