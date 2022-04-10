import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/widgets/snackbar.dart';
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
import 'package:sport_log/widgets/never_pop.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';

class StrengthSessionsPage extends StatefulWidget {
  const StrengthSessionsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StrengthSessionsPage> createState() => StrengthSessionsPageState();
}

class StrengthSessionsPageState extends State<StrengthSessionsPage> {
  final _dataProvider = StrengthSessionDescriptionDataProvider();
  final _logger = Logger('StrengthSessionsPage');
  List<StrengthSessionDescription> _sessions = [];

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;

  @override
  void initState() {
    super.initState();
    _dataProvider
      ..addListener(_update)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider
      ..removeListener(_update)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d(
      'Updating strength sessions with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final ssds = await _dataProvider.getByTimerangeAndMovement(
      from: _dateFilter.start,
      until: _dateFilter.end,
      movement: _movement,
    );
    setState(() => _sessions = ssds);
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_movement?.name ?? "Strength Sessions"),
          actions: [
            IconButton(
              onPressed: () async {
                final Movement? movement = await showMovementPicker(
                  context: context,
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
                await _update();
              },
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _dataProvider.pullFromServer,
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
                      itemBuilder: (context, index) => StrengthSessionCard(
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
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.strength.details,
        arguments: strengthSessionDescription,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strengthSessionDescription.session.datetime
                          .toHumanWithTime(),
                    ),
                    Defaults.sizedBox.vertical.normal,
                    Text(
                      strengthSessionDescription.movement.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                    if (strengthSessionDescription.session.interval !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      Text(
                        "Interval: ${strengthSessionDescription.session.interval!.formatTimeShort}",
                      ),
                    ]
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: strengthSessionDescription.sets
                      .map(
                        (set) => Text(
                          set.toDisplayName(
                            strengthSessionDescription.movement.dimension,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
