import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
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
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');
  final _dataProvider = CardioSessionDescriptionDataProvider.instance;
  List<CardioSessionDescription> _cardioSessionDescriptions = [];

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
      'Updating diary page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final cardioSessionDescriptions =
        await _dataProvider.getByTimerangeAndMovement(
      movementId: _movement?.id,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    setState(() => _cardioSessionDescriptions = cardioSessionDescriptions);
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
        title: Text(_movement?.name ?? "Cardio Sessions"),
        actions: [
          IconButton(
            onPressed: () => Nav.newBase(context, Routes.cardio.routeOverview),
            icon: const Icon(AppIcons.route),
          ),
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
              } else {
                setState(() {
                  _movement = movement;
                });
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
        onRefresh: _pullFromServer,
        child: _cardioSessionDescriptions.isEmpty
            ? SessionsPageTab.cardio.noEntriesText
            : Container(
                padding: const EdgeInsets.all(10),
                child: ListView.separated(
                  itemBuilder: (_, index) => CardioSessionCard(
                    cardioSessionDescription: _cardioSessionDescriptions[index],
                  ),
                  separatorBuilder: (_, __) =>
                      Defaults.sizedBox.vertical.normal,
                  itemCount: _cardioSessionDescriptions.length,
                ),
              ),
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.cardio),
      drawer: MainDrawer(selectedRoute: Routes.cardio.overview),
      floatingActionButton: ExpandableFab(
        icon: const Icon(AppIcons.add),
        buttons: [
          ActionButton(
            icon: const Icon(AppIcons.timer),
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
    final distance = cardioSessionDescription.cardioSession.distance == null
        ? '???'
        : (cardioSessionDescription.cardioSession.distance! / 1000)
            .toStringAsFixed(3);
    final speed = cardioSessionDescription.cardioSession.distance == null ||
            cardioSessionDescription.cardioSession.time == null
        ? '???'
        : ((cardioSessionDescription.cardioSession.distance! / 1000) /
                (cardioSessionDescription.cardioSession.time!.inSeconds / 3600))
            .toStringAsFixed(1);

    late MapboxMapController _sessionMapController;

    return GestureDetector(
      onTap: () => showDetails(context),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Defaults.sizedBox.vertical.small,
            Row(
              children: [
                Expanded(
                  child: Text(
                    cardioSessionDescription
                        .cardioSession.datetime.formatDatetime,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: Text(
                    cardioSessionDescription.movement.name,
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            Defaults.sizedBox.vertical.small,
            cardioSessionDescription.cardioSession.track != null ||
                    cardioSessionDescription.route != null
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                      accessToken: Defaults.mapbox.accessToken,
                      styleString: Defaults.mapbox.style.outdoor,
                      initialCameraPosition: CameraPosition(
                        zoom: 13.0,
                        target: Settings.lastMapPosition,
                      ),
                      onMapCreated: (MapboxMapController controller) =>
                          _sessionMapController = controller,
                      onStyleLoadedCallback: () {
                        final bounds = LatLngBoundsCombine.combinedBounds(
                          cardioSessionDescription.cardioSession.track,
                          cardioSessionDescription.route?.track,
                        );
                        if (bounds != null) {
                          _sessionMapController
                              .moveCamera(CameraUpdate.newLatLngBounds(bounds));
                        }
                        if (cardioSessionDescription.cardioSession.track !=
                            null) {
                          _sessionMapController.addLine(
                            LineOptions(
                              lineColor: "red",
                              lineWidth: 2,
                              geometry: cardioSessionDescription
                                  .cardioSession.track!.latLngs,
                            ),
                          );
                        }
                        if (cardioSessionDescription.route != null) {
                          _sessionMapController.addLine(
                            LineOptions(
                              lineColor: "blue",
                              lineWidth: 2,
                              geometry:
                                  cardioSessionDescription.route!.track.latLngs,
                            ),
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
                      const Text(" no track available"),
                    ],
                  ),
            Defaults.sizedBox.vertical.small,
            Row(
              children: [
                Expanded(
                  child: ValueUnitDescription(
                    value: cardioSessionDescription
                            .cardioSession.time?.formatTime ??
                        "--:--:--",
                    unit: null,
                    description: null,
                  ),
                ),
                Expanded(
                  child: ValueUnitDescription(
                    value: distance,
                    unit: "km",
                    description: null,
                  ),
                ),
                Expanded(
                  child: ValueUnitDescription(
                    value: speed,
                    unit: "km/h",
                    description: null,
                  ),
                ),
              ],
            ),
            Defaults.sizedBox.vertical.small,
          ],
        ),
      ),
    );
  }
}
