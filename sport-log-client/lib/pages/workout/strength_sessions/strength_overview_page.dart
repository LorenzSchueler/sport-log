import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_chart.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';

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
        () => showSimpleToast(context, 'No Internet connection.');
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
      'Updating strength sessions with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final ssds = await _dataProvider.getByTimerangeAndMovement(
      from: _dateFilter.start,
      until: _dateFilter.end,
      movementId: _movement?.id,
    );
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
              final Movement? movement = await showMovementPicker(
                context,
                selectedMovement: _movement,
              );
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
              _movement != null ? AppIcons.filterFilled : AppIcons.filter,
            ),
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
        child: Container(
          padding: Defaults.edgeInsets.normal,
          child: CustomScrollView(
            slivers: [
              if (_sessions.isEmpty)
                SliverFillRemaining(
                  child: SessionsPageTab.strength.noEntriesText,
                ),
              if (_sessions.isNotEmpty && _movement != null)
                SliverToBoxAdapter(
                  child: StrengthChart(
                    movement: _movement!,
                    dateFilterState: _dateFilter,
                  ),
                ),
              if (_sessions.isNotEmpty)
                SliverFillRemaining(
                  child: ListView.separated(
                    itemBuilder: (context, index) => _movement != null
                        ? StrengthSessionCardWithMovement(
                            strengthSessionDescription: _sessions[index],
                          )
                        : StrengthSessionCard(
                            strengthSessionDescription: _sessions[index],
                          ),
                    separatorBuilder: (_, __) =>
                        Defaults.sizedBox.vertical.normal,
                    itemCount: _sessions.length,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SessionTabUtils.bottomNavigationBar(
        context,
        SessionsPageTab.strength,
      ),
      drawer: MainDrawer(selectedRoute: Routes.strength.overview),
      floatingActionButton: FloatingActionButton(
        child: const Icon(AppIcons.add),
        onPressed: () {
          Navigator.pushNamed(context, Routes.strength.edit);
        },
      ),
    );
  }
}

class StrengthSessionCard extends StatelessWidget {
  final StrengthSessionDescription strengthSessionDescription;

  const StrengthSessionCard({
    Key? key,
    required this.strengthSessionDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(strengthSessionDescription.movement.dimension.iconData),
        title: Text(strengthSessionDescription.movement.name),
        subtitle: Text(
          '${strengthSessionDescription.session.datetime.toHumanWithTime()} • ${strengthSessionDescription.stats.numSets} ${plural('set', 'sets', strengthSessionDescription.stats.numSets)}',
        ),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.strength.details,
          arguments: strengthSessionDescription,
        ),
      ),
    );
  }
}

class StrengthSessionCardWithMovement extends StatelessWidget {
  final StrengthSessionDescription strengthSessionDescription;

  const StrengthSessionCardWithMovement({
    Key? key,
    required this.strengthSessionDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          '${strengthSessionDescription.session.datetime.toHumanWithTime()} • ${strengthSessionDescription.stats.numSets} ${plural('set', 'sets', strengthSessionDescription.stats.numSets)}',
        ),
        subtitle: Text(
          strengthSessionDescription.stats
              .toDisplayName(strengthSessionDescription.movement.dimension),
        ),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.strength.details,
          arguments: strengthSessionDescription,
        ),
      ),
    );
  }
}
