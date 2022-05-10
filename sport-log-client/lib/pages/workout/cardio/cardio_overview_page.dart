import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/pages/workout/charts/chart.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');
  final _dataProvider = CardioSessionDescriptionDataProvider();
  List<CardioSessionDescription> _cardioSessionDescriptions = [];

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
      'Updating cardio session page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final cardioSessionDescriptions =
        await _dataProvider.getByTimerangeAndMovement(
      movement: _movement,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    setState(() => _cardioSessionDescriptions = cardioSessionDescriptions);
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_movement?.name ?? "Cardio Sessions"),
          actions: [
            IconButton(
              onPressed: () =>
                  Navigator.of(context).newBase(Routes.cardio.routeOverview),
              icon: const Icon(AppIcons.route),
            ),
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
          child: _cardioSessionDescriptions.isEmpty
              ? SessionsPageTab.cardio.noEntriesText
              : Container(
                  padding: Defaults.edgeInsets.normal,
                  child: Column(
                    children: [
                      if (_movement != null) ...[
                        Chart(
                          chartValues: _cardioSessionDescriptions
                              .map(
                                (s) => ChartValue(
                                  datetime: s.cardioSession.datetime,
                                  value:
                                      (s.cardioSession.distance?.toDouble() ??
                                              0.0) /
                                          1000,
                                ),
                              )
                              .toList(),
                          desc: true,
                          dateFilterState: _dateFilter,
                          yFromZero: true,
                          aggregatorType: AggregatorType.sum,
                        ),
                        Defaults.sizedBox.vertical.normal,
                      ],
                      Expanded(
                        child: ListView.separated(
                          itemBuilder: (_, index) => CardioSessionCard(
                            cardioSessionDescription:
                                _cardioSessionDescriptions[index],
                            key: ValueKey(
                              _cardioSessionDescriptions[index]
                                  .cardioSession
                                  .id,
                            ),
                          ),
                          separatorBuilder: (_, __) =>
                              Defaults.sizedBox.vertical.normal,
                          itemCount: _cardioSessionDescriptions.length,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: SessionTabUtils.bottomNavigationBar(
          context,
          SessionsPageTab.cardio,
        ),
        drawer: MainDrawer(selectedRoute: Routes.cardio.overview),
        floatingActionButton: ExpandableFab(
          icon: const Icon(AppIcons.add),
          buttons: [
            ActionButton(
              icon: const Icon(AppIcons.stopwatch),
              onPressed: () => Navigator.pushNamed(
                context,
                Routes.cardio.trackingSettings,
              ),
            ),
            ActionButton(
              icon: const Icon(AppIcons.notes),
              onPressed: () => Navigator.pushNamed(
                context,
                Routes.cardio.cardioEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardioSessionCard extends StatelessWidget {
  final CardioSessionDescription cardioSessionDescription;

  const CardioSessionCard({Key? key, required this.cardioSessionDescription})
      : super(key: key);

  void showDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.cardio.cardioDetails,
      arguments: cardioSessionDescription,
    );
  }

  @override
  Widget build(BuildContext context) {
    late MapboxMapController _sessionMapController;

    return GestureDetector(
      onTap: () => showDetails(context),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cardioSessionDescription.cardioSession.datetime
                        .toHumanDateTime(),
                  ),
                  Text(
                    cardioSessionDescription.movement.name,
                    style: Theme.of(context).textTheme.subtitle1,
                  )
                ],
              ),
            ),
            cardioSessionDescription.cardioSession.track != null ||
                    cardioSessionDescription.route != null
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                      accessToken: Config.instance.accessToken,
                      styleString: MapboxStyles.OUTDOORS,
                      initialCameraPosition: Settings.lastMapPosition,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      onMapCreated: (MapboxMapController controller) =>
                          _sessionMapController = controller,
                      onStyleLoadedCallback: () {
                        _sessionMapController.setBoundsFromTracks(
                          cardioSessionDescription.cardioSession.track,
                          cardioSessionDescription.route?.track,
                          padded: true,
                        );
                        if (cardioSessionDescription.cardioSession.track !=
                            null) {
                          _sessionMapController.addTrackLine(
                            cardioSessionDescription.cardioSession.track!,
                          );
                        }
                        if (cardioSessionDescription.route?.track != null) {
                          _sessionMapController.addRouteLine(
                            cardioSessionDescription.route!.track!,
                          );
                        }
                      },
                      onMapClick: (_, __) => showDetails(context),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.route,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Defaults.sizedBox.horizontal.normal,
                      const Text("no track available"),
                    ],
                  ),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueUnitDescription.timeSmall(
                    cardioSessionDescription.cardioSession.time,
                  ),
                  ValueUnitDescription.distanceSmall(
                    cardioSessionDescription.cardioSession.distance,
                  ),
                  ValueUnitDescription.speedSmall(
                    cardioSessionDescription.cardioSession.speed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
