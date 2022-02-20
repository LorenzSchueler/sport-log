import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/list_extension.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/expandable_fab.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');
  //final _dataProvider = CardioSessionDescriptionDataProvider.instance;
  final List<CardioSessionDescription> _cardioSessionDescriptions = [];

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;

  //CardioSession(
  //id: randomId(),
  //userId: Settings.userId!,
  //movementId: Int64(1),
  //cardioType: CardioType.training,
  //datetime: DateTime.now(),
  //distance: 15034,
  //ascent: 308,
  //descent: 297,
  //time: const Duration(seconds: 4189),
  //calories: null,
  //track: [
  //Position(
  //longitude: 11.33,
  //latitude: 47.27,
  //elevation: 600,
  //distance: 0,
  //time: const Duration(seconds: 0)),
  //Position(
  //longitude: 11.331,
  //latitude: 47.27,
  //elevation: 650,
  //distance: 1000,
  //time: const Duration(seconds: 200)),
  //Position(
  //longitude: 11.33,
  //latitude: 47.272,
  //elevation: 600,
  //distance: 2000,
  //time: const Duration(seconds: 500)),
  //],
  //avgCadence: 167,
  //cadence: null,
  //avgHeartRate: 189,
  //heartRate: null,
  //routeId: null,
  //comments: null,
  //deleted: false),
  //CardioSession(
  //id: randomId(),
  //userId: Settings.userId!,
  //movementId: Int64(1),
  //cardioType: CardioType.activeRecovery,
  //datetime: DateTime.now(),
  //distance: 5091,
  //ascent: 8,
  //descent: 7,
  //time: const Duration(seconds: 489),
  //calories: null,
  //track: null,
  //avgCadence: 147,
  //cadence: null,
  //avgHeartRate: 169,
  //heartRate: null,
  //routeId: null,
  //comments: "some comments here",
  //deleted: false)
  //];

  @override
  void initState() {
    super.initState();
    //_dataProvider.addListener(update);
    //_dataProvider.onNoInternetConnection =
    //() => showSimpleSnackBar(context, 'No Internet connection.');
    update();
  }

  @override
  void dispose() {
    //_dataProvider.removeListener(update);
    //_dataProvider.onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> update() async {
    _logger.d(
        'Updating diary page with start = ${_dateFilter.start}, end = ${_dateFilter.end}');
    // final cardioSessions =
    // await _dataProvider.getByTimerange(_dateFilter.start, _dateFilter.end);
    // setState(() => _cardioSessions = cardioSessions);
  }

  // full update (from server)
  Future<void> _refreshPage() async {
    //await _dataProvider.doFullUpdate().onError((error, stackTrace) {
    //if (error is ApiError) {
    //ScaffoldMessenger.of(context)
    //.showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
    //}
    //});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movement?.name ?? "Cardio Sessions"),
        actions: [
          IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.cardio.routeOverview),
              icon: const Icon(CustomIcons.route)),
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
            onFilterChanged: (dateFilter) async {
              setState(() => _dateFilter = dateFilter);
              update();
            },
          ),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (_, index) => CardioSessionCard(
            cardioSessionDescription: _cardioSessionDescriptions[index]),
        itemCount: _cardioSessionDescriptions.length,
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.cardio),
      drawer: MainDrawer(selectedRoute: Routes.cardio.overview),
      floatingActionButton: ExpandableFab(
        icon: const Icon(Icons.add),
        buttons: [
          ActionButton(
            icon: const Icon(CustomIcons.stopwatch),
            onPressed: () => Navigator.of(context)
                .pushNamed(Routes.cardio.trackingSettings)
                .then(_handleNewCardioSession),
          ),
          ActionButton(
            icon: const Icon(Icons.notes_rounded),
            onPressed: () => Navigator.of(context)
                .pushNamed(Routes.cardio.cardioEdit)
                .then(_handleNewCardioSession),
          ),
        ],
      ),
    );
  }

  void _handleNewCardioSession(dynamic object) {
    if (object is ReturnObject<CardioSessionDescription>) {
      switch (object.action) {
        case ReturnAction.created:
          setState(() {
            _cardioSessionDescriptions.add(object.payload);
            _cardioSessionDescriptions.sortBy((c) => c.cardioSession.datetime);
          });
          break;
        case ReturnAction.updated:
          setState(() {
            _cardioSessionDescriptions.update(object.payload, by: (o) => o.id);
            _cardioSessionDescriptions.sortBy((c) => c.cardioSession.datetime);
          });
          break;
        case ReturnAction.deleted:
          setState(() => _cardioSessionDescriptions.delete(object.payload,
              by: (c) => c.id));
      }
    } else {
      _logger.i("poped item is not a ReturnObject");
    }
  }
}

class CardioSessionCard extends StatelessWidget {
  final CardioSessionDescription cardioSessionDescription;

  const CardioSessionCard({Key? key, required this.cardioSessionDescription})
      : super(key: key);

  void showDetails(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.cardio.cardioDetails,
        arguments: cardioSessionDescription);
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
    final duration = cardioSessionDescription.cardioSession.time == null
        ? "???"
        : formatTime(cardioSessionDescription.cardioSession.time!);

    late MapboxMapController _sessionMapController;

    return GestureDetector(
        onTap: () => showDetails(context),
        child: Card(
          child: Column(children: [
            Defaults.sizedBox.vertical.small,
            Row(children: [
              Expanded(
                child: Text(
                  formatDatetime(
                      cardioSessionDescription.cardioSession.datetime),
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
            ]),
            Defaults.sizedBox.vertical.small,
            cardioSessionDescription.cardioSession.track != null
                ? SizedBox(
                    height: 150,
                    child: MapboxMap(
                      accessToken: Defaults.mapbox.accessToken,
                      styleString: Defaults.mapbox.style.outdoor,
                      initialCameraPosition: CameraPosition(
                        zoom: 13.0,
                        target: cardioSessionDescription
                            .cardioSession.track!.first.latLng,
                      ),
                      onMapCreated: (MapboxMapController controller) =>
                          _sessionMapController = controller,
                      onStyleLoadedCallback: () {
                        _sessionMapController.addLine(LineOptions(
                            lineColor: "red",
                            geometry: cardioSessionDescription
                                .cardioSession.track!
                                .map((c) => c.latLng)
                                .toList()));
                      },
                      onMapClick: (_, __) => showDetails(context),
                    ))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CustomIcons.route),
                      Text(" no track available"),
                    ],
                  ),
            Defaults.sizedBox.vertical.small,
            Row(children: [
              Expanded(
                child: ValueUnitDescription(
                  value: duration,
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
            ]),
            Defaults.sizedBox.vertical.small,
          ]),
        ));
  }
}
