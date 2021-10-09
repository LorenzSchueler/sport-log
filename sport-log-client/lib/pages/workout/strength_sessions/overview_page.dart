import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/ui_cubit.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/routes.dart';

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
  List<StrengthSessionWithStats> _sessions = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(update);
    _dataProvider.onNoInternetConnection(
        () => showSimpleSnackBar(context, 'No Internet connection.'));
    update();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(update);
    _dataProvider.onNoInternetConnection(null);
    super.dispose();
  }

  Future<void> update([SessionsUiState? uiState]) async {
    final state = uiState ?? context.read<SessionsUiCubit>().state;
    _logger.d(
        'Updating strength sessions with start = ${state.dateFilter.start}, end = ${state.dateFilter.end}');
    _dataProvider
        .getSessionsWithStats(
            from: state.dateFilter.start,
            until: state.dateFilter.end,
            movementId: state.movement?.id)
        .then((ssds) async {
      setState(() => _sessions = ssds);
    });
  }

  // will be called by workout/sessions page via global key
  void onFabTapped() {
    _logger.d('FAB tapped!');
  }

  // full update (from server)
  Future<void> _refreshPage() async {
    await _dataProvider.doFullUpdate().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsUiCubit, SessionsUiState>(
      listenWhen: (oldState, newState) {
        return newState.isStrengthPage &&
            (oldState.dateFilter != newState.dateFilter ||
                oldState.movement != newState.movement);
      },
      listener: (context, state) {
        update(state);
      },
      buildWhen: (oldState, newState) {
        return newState.isStrengthPage &&
            (oldState.dateFilter != newState.dateFilter ||
                oldState.movement != newState.movement);
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: _refreshPage,
          child: CustomScrollView(
            slivers: [
              if (_sessions.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No data :(')),
                ),
              if (_sessions.isNotEmpty && state.isMovementSelected)
                const SliverToBoxAdapter(
                  child: StrengthChart(),
                ),
              if (_sessions.isNotEmpty)
                SliverList(
                  delegate: state.isMovementSelected
                      ? SliverChildBuilderDelegate(
                          (context, index) => _sessionToWidgetWithMovement(
                              _sessions[index], index),
                          childCount: _sessions.length,
                        )
                      : SliverChildBuilderDelegate(
                          (context, index) => _sessionToWidgetWithoutMovement(
                              _sessions[index], index),
                          childCount: _sessions.length),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _sessionToWidgetWithMovement(StrengthSessionWithStats s, int index) {
    return ListTile(
      title: Text(
          '${s.session.datetime.toHumanWithTime()} • ${s.stats.numSets} ${plural('set', 'sets', s.stats.numSets)}'),
      subtitle: Text(s.stats.toDisplayName(s.movement.dimension)),
      onTap: () => Navigator.of(context)
          .pushNamed(Routes.strength.details, arguments: s.session.id),
    );
  }

  Widget _sessionToWidgetWithoutMovement(
      StrengthSessionWithStats s, int index) {
    return ListTile(
      leading: Icon(s.movement.dimension.iconData),
      title: Text(s.movement.name),
      subtitle: Text(
          '${s.session.datetime.toHumanWithTime()} • ${s.stats.numSets} ${plural('set', 'sets', s.stats.numSets)}'),
      onTap: () => Navigator.of(context)
          .pushNamed(Routes.strength.details, arguments: s.session.id),
    );
  }
}
