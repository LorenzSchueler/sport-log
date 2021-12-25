import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/movement_picker.dart';

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

  Future<void> update() async {
    _logger.d(
        'Updating strength sessions with start = ${_dateFilter.start}, end = ${_dateFilter.end}');
    _dataProvider
        .getSessionsWithStats(
            from: _dateFilter.start,
            until: _dateFilter.end,
            movementId: _movement?.id)
        .then((ssds) async {
      setState(() => _sessions = ssds);
    });
  }

  Widget? fab(BuildContext context) {
    _logger.d('FAB tapped!');

    return null;
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

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;
  final SessionsPageTab sessionsPageTab = SessionsPageTab.strength;
  final String route = Routes.strength.overview;
  final String defaultTitle = "Strength Sessions";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movement?.name ?? defaultTitle),
        actions: [
          IconButton(
            onPressed: () async {
              final Movement? movement = await showMovementPickerDialog(context,
                  selectedMovement: _movement);
              if (movement == null) {
                return;
              } else if (movement.id == _movement?.id) {
                setState(() {
                  _movement = null;
                });
              } else {
                setState(() {
                  _movement = movement;
                });
              }
            },
            icon: Icon(_movement != null
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: DateFilter(
            initialState: _dateFilter,
            onFilterChanged: (dateFilter) => setState(() {
              _dateFilter = dateFilter;
            }),
          ),
        ),
      ),
      body: _innerbuild(context),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
      floatingActionButton: fab(context),
    );
  }

  Widget _innerbuild(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPage,
      child: CustomScrollView(
        slivers: [
          if (_sessions.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No data :(')),
            ),
          if (_sessions.isNotEmpty && _movement != null)
            SliverToBoxAdapter(
              child: StrengthChart(
                movement: _movement!,
                dateFilterState: _dateFilter,
              ),
            ),
          if (_sessions.isNotEmpty)
            SliverList(
              delegate: _movement != null
                  ? SliverChildBuilderDelegate(
                      (context, index) =>
                          _sessionToWidgetWithMovement(_sessions[index], index),
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
