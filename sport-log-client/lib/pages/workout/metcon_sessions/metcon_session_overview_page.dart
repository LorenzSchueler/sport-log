import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_description_card.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_results_card.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/picker/metcon_picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MetconSessionsPage extends StatefulWidget {
  const MetconSessionsPage({Key? key}) : super(key: key);

  @override
  State<MetconSessionsPage> createState() => _MetconSessionsPageState();
}

class _MetconSessionsPageState extends State<MetconSessionsPage> {
  final _logger = Logger('MetconSessionsPage');
  final _dataProvider = MetconSessionDescriptionDataProvider();
  List<MetconSessionDescription> _metconSessionDescriptions = [];
  MetconRecords _metconRecords = {};
  bool _isLoading = false;

  DateFilterState _dateFilter = MonthFilter.current();
  Metcon? _metcon;

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
      'Updating metcon session page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final metconSessionDescriptions =
        await _dataProvider.getByTimerangeAndMetcon(
      metcon: _metcon,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    final records = await _dataProvider.getMetconRecords();
    setState(() {
      _metconSessionDescriptions = metconSessionDescriptions;
      _metconRecords = records;
      _isLoading = false;
    });
    _logger.d("Updated metcon sessions.");
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_metcon?.name ?? "Metcon Sessions"),
          actions: [
            IconButton(
              onPressed: () =>
                  Navigator.of(context).newBase(Routes.metcon.overview),
              icon: const Icon(AppIcons.notes),
            ),
            IconButton(
              onPressed: () async {
                final Metcon? metcon = await showMetconPicker(
                  context: context,
                  selectedMetcon: _metcon,
                );
                if (metcon == null) {
                  return;
                } else if (metcon.id == _metcon?.id) {
                  setState(() {
                    _metcon = null;
                  });
                  await _update();
                } else {
                  setState(() {
                    _metcon = metcon;
                  });
                  await _update();
                }
              },
              icon: Icon(
                _metcon != null ? AppIcons.filterFilled : AppIcons.filter,
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
              child: _metconSessionDescriptions.isEmpty
                  ? SessionsPageTab.metcon.noEntriesText
                  : Container(
                      padding: Defaults.edgeInsets.normal,
                      child: _metcon != null &&
                              _metconSessionDescriptions.isNotEmpty
                          ? ListView.separated(
                              itemBuilder: (_, index) {
                                if (index == 0) {
                                  return MetconDescriptionCard(
                                    metconDescription:
                                        _metconSessionDescriptions
                                            .first.metconDescription,
                                  );
                                } else if (index == 1) {
                                  return MetconSessionResultsCard(
                                    metconSessionDescription: null,
                                    metconSessionDescriptions:
                                        _metconSessionDescriptions,
                                    metconRecords: _metconRecords,
                                  );
                                } else {
                                  return MetconSessionCard(
                                    metconSessionDescription:
                                        _metconSessionDescriptions[index - 2],
                                    metconRecords: _metconRecords,
                                  );
                                }
                              },
                              separatorBuilder: (_, __) =>
                                  Defaults.sizedBox.vertical.normal,
                              itemCount: _metconSessionDescriptions.length + 2,
                            )
                          : ListView.separated(
                              itemBuilder: (_, index) => MetconSessionCard(
                                metconSessionDescription:
                                    _metconSessionDescriptions[index],
                                metconRecords: _metconRecords,
                              ),
                              separatorBuilder: (_, __) =>
                                  Defaults.sizedBox.vertical.normal,
                              itemCount: _metconSessionDescriptions.length,
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
          SessionsPageTab.metcon,
        ),
        drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
        floatingActionButton: FloatingActionButton(
          child: const Icon(AppIcons.add),
          onPressed: () {
            Navigator.pushNamed(context, Routes.metcon.sessionEdit);
          },
        ),
      ),
    );
  }
}

class MetconSessionCard extends StatelessWidget {
  MetconSessionCard({
    required this.metconSessionDescription,
    required MetconRecords metconRecords,
    Key? key,
  })  : metconRecord = metconRecords.isMetconRecord(metconSessionDescription),
        super(key: key);

  final MetconSessionDescription metconSessionDescription;
  final bool metconRecord;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.metcon.sessionDetails,
          arguments: metconSessionDescription,
        );
      },
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
                      metconSessionDescription.metconSession.datetime
                          .toHumanDateTime(),
                    ),
                    Defaults.sizedBox.vertical.normal,
                    Text(
                      metconSessionDescription.metconDescription.metcon.name,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    if (metconRecord) ...[
                      Defaults.sizedBox.vertical.normal,
                      const Icon(
                        AppIcons.medal,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metconSessionDescription.longResultDescription),
                    Defaults.sizedBox.vertical.normal,
                    Row(
                      children: [
                        const Text("Rx "),
                        Icon(
                          metconSessionDescription.metconSession.rx
                              ? AppIcons.check
                              : AppIcons.close,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
