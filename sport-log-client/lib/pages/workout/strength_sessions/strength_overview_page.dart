import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/models/strength/strength_records.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_chart.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class StrengthSessionsPage extends StatefulWidget {
  const StrengthSessionsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StrengthSessionsPage> createState() => _StrengthSessionsPageState();
}

class _StrengthSessionsPageState extends State<StrengthSessionsPage> {
  final _dataProvider = StrengthSessionDescriptionDataProvider();
  final _logger = Logger('StrengthSessionsPage');
  List<StrengthSessionDescription> _sessions = [];
  StrengthRecords _strengthRecords = {};
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
    _logger.d(
      'Updating strength sessions with start = ${_dateFilter.start}, end = ${_dateFilter.end}, movement = ${_movement?.name}',
    );
    final ssds = await _dataProvider.getByTimerangeAndMovement(
      from: _dateFilter.start,
      until: _dateFilter.end,
      movement: _movement,
    );
    final records = await _dataProvider.getStrengthRecords();
    setState(() {
      _sessions = ssds;
      _strengthRecords = records;
      _isLoading = false;
    });
    _logger.d("Updated strength sessions.");
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
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            RefreshIndicator(
              onRefresh: _dataProvider.pullFromServer,
              child: _sessions.isEmpty
                  ? SessionsPageTab.strength.noEntriesText
                  : Container(
                      padding: Defaults.edgeInsets.normal,
                      child: Column(
                        children: [
                          if (_movement != null) ...[
                            StrengthChart(
                              strengthSessionDescriptions: _sessions,
                              dateFilterState: _dateFilter,
                            ),
                            Defaults.sizedBox.vertical.normal,
                            StrengthRecodsCard(
                              strengthRecords: _strengthRecords,
                              movement: _movement!,
                            ),
                            Defaults.sizedBox.vertical.normal,
                          ],
                          Expanded(
                            child: ListView.separated(
                              itemBuilder: (context, index) =>
                                  StrengthSessionCard(
                                strengthSessionDescription: _sessions[index],
                                strengthRecords: _strengthRecords,
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
            if (_isLoading)
              const Positioned(
                top: 40,
                child: RefreshProgressIndicator(),
              ),
          ],
        ),
        bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
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
  StrengthSessionCard({
    Key? key,
    required this.strengthSessionDescription,
    required this.strengthRecords,
  })  : strengthRecordTypes =
            strengthRecords.getCombinedRecordTypes(strengthSessionDescription),
        super(key: key);

  final StrengthSessionDescription strengthSessionDescription;
  final StrengthRecords strengthRecords;
  final List<StrengthRecordType> strengthRecordTypes;

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
                          .toHumanDateTime(),
                    ),
                    Defaults.sizedBox.vertical.normal,
                    Text(
                      strengthSessionDescription.movement.name,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    if (strengthRecordTypes.isNotEmpty) ...[
                      Defaults.sizedBox.vertical.normal,
                      StrengthRecordMarkers(
                        strengthRecordTypes: strengthRecordTypes,
                      ),
                    ],
                    if (strengthSessionDescription.session.interval !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      Text(
                        "Interval: ${strengthSessionDescription.session.interval!.formatTimeShort}",
                      ),
                    ],
                    if (strengthSessionDescription.session.comments !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      Text(strengthSessionDescription.session.comments!),
                    ],
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

class StrengthRecodsCard extends StatelessWidget {
  StrengthRecodsCard({
    Key? key,
    required this.movement,
    required StrengthRecords strengthRecords,
  })  : strengthRecord = strengthRecords[movement.id],
        super(key: key);

  final Movement movement;
  final StrengthRecord? strengthRecord;

  @override
  Widget build(BuildContext context) {
    String countText = "";
    if (strengthRecord != null) {
      switch (movement.dimension) {
        case MovementDimension.reps:
          countText = "${strengthRecord!.maxCount} reps";
          break;
        case MovementDimension.time:
          countText =
              Duration(milliseconds: strengthRecord!.maxCount).formatMsMill;
          break;
        case MovementDimension.distance:
          countText = '${strengthRecord!.maxCount} m';
          break;
        case MovementDimension.energy:
          countText = '${strengthRecord!.maxCount} cal';
          break;
      }
    }

    return strengthRecord == null
        ? Container()
        : Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (strengthRecord!.maxWeight != null) ...[
                    const Icon(
                      AppIcons.medal,
                      color: Colors.orange,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.small,
                    Text(
                      "${strengthRecord!.maxWeight!.round()} kg",
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ],
                  const Icon(
                    AppIcons.medal,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  Defaults.sizedBox.horizontal.small,
                  Text(
                    countText,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  if (strengthRecord!.maxEorm != null) ...[
                    Defaults.sizedBox.horizontal.normal,
                    const Icon(
                      AppIcons.medal,
                      color: Colors.grey,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.small,
                    Text(
                      "${strengthRecord!.maxEorm!.round()} kg",
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ],
              ),
            ),
          );
  }
}

class StrengthRecordMarkers extends StatelessWidget {
  const StrengthRecordMarkers({
    Key? key,
    required this.strengthRecordTypes,
  }) : super(key: key);

  final List<StrengthRecordType> strengthRecordTypes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: strengthRecordTypes
          .map(
            (recordType) {
              switch (recordType) {
                case StrengthRecordType.maxWeight:
                  return [
                    const Icon(
                      AppIcons.medal,
                      color: Colors.orange,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ];
                case StrengthRecordType.maxCount:
                  return [
                    const Icon(
                      AppIcons.medal,
                      color: Colors.yellow,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ];
                case StrengthRecordType.maxEorm:
                  return [
                    const Icon(
                      AppIcons.medal,
                      color: Colors.grey,
                      size: 20,
                    ),
                    Defaults.sizedBox.horizontal.normal,
                  ];
              }
            },
          )
          .toList()
          .flattened
          .toList(),
    );
  }
}
