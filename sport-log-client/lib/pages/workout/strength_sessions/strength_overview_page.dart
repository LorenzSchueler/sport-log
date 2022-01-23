import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';

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

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;
  final SessionsPageTab sessionsPageTab = SessionsPageTab.strength;
  final String route = Routes.strength.overview;
  final String defaultTitle = "Strength Sessions";

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
      body: RefreshIndicator(
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
                  delegate: SliverChildBuilderDelegate(
                (context, index) => _movement != null
                    ? _sessionCardWithMovement(
                        _sessions[index],
                      )
                    : StrengthSessionCard(
                        strengthSessionWithStats: _sessions[index],
                      ),
                childCount: _sessions.length,
              )),
          ],
        ),
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
      floatingActionButton: null,
    );
  }

  Widget _sessionCardWithMovement(StrengthSessionWithStats s) {
    return Card(
        child: ListTile(
      title: Text(
          '${s.session.datetime.toHumanWithTime()} • ${s.stats.numSets} ${plural('set', 'sets', s.stats.numSets)}'),
      subtitle: Text(s.stats.toDisplayName(s.movement.dimension)),
      onTap: () => Navigator.of(context)
          .pushNamed(Routes.strength.details, arguments: s.session.id),
    ));
  }
}

class StrengthSessionCard extends StatelessWidget {
  final StrengthSessionWithStats strengthSessionWithStats;

  const StrengthSessionCard({Key? key, required this.strengthSessionWithStats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
      leading: Icon(strengthSessionWithStats.movement.dimension.iconData),
      title: Text(strengthSessionWithStats.movement.name),
      subtitle: Text(
          '${strengthSessionWithStats.session.datetime.toHumanWithTime()} • ${strengthSessionWithStats.stats.numSets} ${plural('set', 'sets', strengthSessionWithStats.stats.numSets)}'),
      onTap: () => Navigator.of(context).pushNamed(Routes.strength.details,
          arguments: strengthSessionWithStats.session.id),
    ));
  }
}