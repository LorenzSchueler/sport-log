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
import 'package:sport_log/widgets/app_icons.dart';
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
  final _dataProvider = StrengthSessionDescriptionDataProvider.instance;
  final _logger = Logger('StrengthSessionsPage');
  List<StrengthSessionDescription> _sessions = [];

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _dataProvider.onNoInternetConnection =
        () => showSimpleSnackBar(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    _dataProvider.onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d(
        'Updating strength sessions with start = ${_dateFilter.start}, end = ${_dateFilter.end}');
    final ssds = await _dataProvider.getByTimerangeAndMovement(
        from: _dateFilter.start,
        until: _dateFilter.end,
        movementId: _movement?.id);
    setState(() => _sessions = ssds);
  }

  Future<void> _pullFromServer() async {
    await _dataProvider.pullFromServer().onError((error, stackTrace) {
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
        title: Text(_movement?.name ?? "Strength Sessions"),
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
                await _update();
              } else {
                setState(() {
                  _movement = movement;
                });
                await _update();
              }
              _logger.i("selected movement: ${movement.name}");
            },
            icon: Icon(
                _movement != null ? AppIcons.filterFilled : AppIcons.filter),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: DateFilter(
            initialState: _dateFilter,
            onFilterChanged: (dateFilter) async {
              setState(() => _dateFilter = dateFilter);
              _update();
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _pullFromServer,
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
      bottomNavigationBar: SessionTabUtils.bottomNavigationBar(
          context, SessionsPageTab.strength),
      drawer: MainDrawer(selectedRoute: Routes.strength.overview),
      floatingActionButton: FloatingActionButton(
          child: const Icon(AppIcons.add),
          onPressed: () {
            Navigator.pushNamed(context, Routes.strength.edit);
          }),
    );
  }

  Widget _sessionCardWithMovement(StrengthSessionDescription s) {
    return Card(
        child: ListTile(
      title: Text(
          '${s.session.datetime.toHumanWithTime()} • ${s.stats.numSets} ${plural('set', 'sets', s.stats.numSets)}'),
      subtitle: Text(s.stats.toDisplayName(s.movement.dimension)),
      onTap: () => Navigator.pushNamed(context, Routes.strength.details,
          arguments: s.session.id),
    ));
  }
}

class StrengthSessionCard extends StatelessWidget {
  final StrengthSessionDescription strengthSessionWithStats;

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
      onTap: () => Navigator.pushNamed(context, Routes.strength.details,
          arguments: strengthSessionWithStats.session.id),
    ));
  }
}
