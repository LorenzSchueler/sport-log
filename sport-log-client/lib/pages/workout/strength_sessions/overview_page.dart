import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/ui_cubit.dart';

import 'strength_chart.dart';

class StrengthSessionsPage extends StatefulWidget {
  const StrengthSessionsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StrengthSessionsPage> createState() => StrengthSessionsPageState();
}

class StrengthSessionsPageState extends State<StrengthSessionsPage> {
  final _dataProvider = StrengthDataProvider.instance;
  final _logger = Logger('StrengthSessionsPage');
  List<StrengthSessionDescription> _ssds = [];

  @override
  void initState() {
    super.initState();
    final state = context.read<SessionsUiCubit>().state;
    update(state);
  }

  Future<void> update(SessionsUiState state) async {
    _logger.d(
        'Updating strength sessions with start = ${state.dateFilter.start}, end = ${state.dateFilter.end}');
    _dataProvider
        .getSessionsWithStats(
            from: state.dateFilter.start,
            until: state.dateFilter.end,
            movementName: state.movement?.name)
        .then((ssds) async {
      setState(() => _ssds = ssds);
    });
  }

  // will be called by workout/sessions page via global key
  void onFabTapped(BuildContext context) {
    _logger.d('FAB tapped!');
  }

  // full update (from server)
  Future<void> _refreshPage(SessionsUiState state) async {
    await _dataProvider.doFullUpdate().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
    update(state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsUiCubit, SessionsUiState>(
        builder: (context, state) => RefreshIndicator(
              onRefresh: () => _refreshPage(state),
              child: _buildStrengthSessionList(state),
            ),
        listenWhen: (oldState, newState) {
          return newState.isStrengthPage &&
              (oldState.dateFilter != newState.dateFilter ||
                  oldState.movement != newState.movement);
        },
        listener: (context, state) {
          update(state);
        });
  }

  Widget _chart(SessionsUiState state) {
    if (!state.isMovementSelected) {
      return const SizedBox.shrink();
    }
    return const StrengthChart();
  }

  Widget _buildStrengthSessionList(SessionsUiState state) {
    if (_ssds.isEmpty) {
      return const Center(child: Text('No strength sessions there.'));
    }
    return Scrollbar(
      child: ListView.builder(
        itemBuilder: (_, index) => _strengthSessionBuilder(state, index),
        itemCount: _ssds.length + 1,
        shrinkWrap: true,
      ),
    );
  }

  // TODO: put into seperate widget
  Widget _strengthSessionBuilder(SessionsUiState state, int index) {
    if (index == 0) {
      assert(_ssds.isNotEmpty);
      return _chart(state);
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
    final String title =
        state.isMovementSelected ? [date, time].join(' · ') : ssd.movement.name;
    final subtitleParts = state.isMovementSelected
        ? [sets, if (duration != null) duration]
        : [date, time, sets, if (duration != null) duration];
    final subtitle = subtitleParts.join(' · ');
    final String text = ssd.strengthSets
            ?.map((ss) => ss.toDisplayName(ssd.movement.dimension))
            .join(', ') ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ExpansionTileCard(
        // dirty fix for forcing an expansion tile card to be non-expanded at the start
        // (without it, an expanded card might show an everloading circular progress indicator)
        key:
            ValueKey(Object.hash(ssd.id, state.dateFilter, state.movement?.id)),
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
