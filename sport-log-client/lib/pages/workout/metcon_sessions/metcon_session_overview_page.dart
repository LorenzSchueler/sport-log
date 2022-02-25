import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';

class MetconSessionsPage extends StatefulWidget {
  const MetconSessionsPage({Key? key}) : super(key: key);

  @override
  State<MetconSessionsPage> createState() => MetconSessionsPageState();
}

class MetconSessionsPageState extends State<MetconSessionsPage> {
  final _logger = Logger('MetconSessionsPage');
  final _dataProvider = MetconSessionDescriptionDataProvider.instance;
  List<MetconSessionDescription> _metconSessionDescriptions = [];

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
      'Updating metcon session page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final metconSessionDescriptions =
        await _dataProvider.getByTimerangeAndMovement(
      movementId: _movement?.id,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    setState(() => _metconSessionDescriptions = metconSessionDescriptions);
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
        title: Text(_movement?.name ?? "Metcon Sessions"),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.metcon.overview),
            icon: const Icon(AppIcons.notes),
          ),
          IconButton(
            onPressed: () async {
              final Movement? movement = await showMovementPickerDialog(
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
        child: _metconSessionDescriptions.isEmpty
            ? SessionsPageTab.metcon.noEntriesText
            : ListView.builder(
                itemBuilder: (_, index) => MetconSessionCard(
                  metconSessionDescription: _metconSessionDescriptions[index],
                ),
                itemCount: _metconSessionDescriptions.length,
              ),
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.metcon),
      drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
      floatingActionButton: FloatingActionButton(
        child: const Icon(AppIcons.add),
        onPressed: () {
          Navigator.pushNamed(context, Routes.metcon.sessionEdit);
        },
      ),
    );
  }
}

class MetconSessionCard extends StatelessWidget {
  final MetconSessionDescription metconSessionDescription;

  const MetconSessionCard({Key? key, required this.metconSessionDescription})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.metcon.sessionEdit,
          arguments: metconSessionDescription,
        );
      },
      child: Card(
        child: ListTile(
          leading: Icon(
            metconSessionDescription.metconDescription.metcon.metconType.icon,
          ),
          trailing: metconSessionDescription.metconSession.rx
              ? const Icon(AppIcons.checkCircle)
              : null,
          title: Text(metconSessionDescription.metconDescription.name),
          subtitle: Text(metconSessionDescription.longResultDescription),
          onTap: () => Navigator.pushNamed(
            context,
            Routes.metcon.sessionDetails,
            arguments: metconSessionDescription,
          ),
        ),
      ),
    );
  }
}
