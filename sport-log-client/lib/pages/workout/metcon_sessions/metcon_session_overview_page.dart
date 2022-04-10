import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/never_pop.dart';
import 'package:sport_log/widgets/picker/metcon_picker.dart';

class MetconSessionsPage extends StatefulWidget {
  const MetconSessionsPage({Key? key}) : super(key: key);

  @override
  State<MetconSessionsPage> createState() => MetconSessionsPageState();
}

class MetconSessionsPageState extends State<MetconSessionsPage> {
  final _logger = Logger('MetconSessionsPage');
  final _dataProvider = MetconSessionDescriptionDataProvider();
  List<MetconSessionDescription> _metconSessionDescriptions = [];

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
    _logger.d(
      'Updating metcon session page with start = ${_dateFilter.start}, end = ${_dateFilter.end}',
    );
    final metconSessionDescriptions =
        await _dataProvider.getByTimerangeAndMetcon(
      metcon: _metcon,
      from: _dateFilter.start,
      until: _dateFilter.end,
    );
    setState(() => _metconSessionDescriptions = metconSessionDescriptions);
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
        body: RefreshIndicator(
          onRefresh: _dataProvider.pullFromServer,
          child: _metconSessionDescriptions.isEmpty
              ? SessionsPageTab.metcon.noEntriesText
              : Container(
                  padding: Defaults.edgeInsets.normal,
                  child: ListView.separated(
                    itemBuilder: (_, index) => MetconSessionCard(
                      metconSessionDescription:
                          _metconSessionDescriptions[index],
                    ),
                    separatorBuilder: (_, __) =>
                        Defaults.sizedBox.vertical.normal,
                    itemCount: _metconSessionDescriptions.length,
                  ),
                ),
        ),
        bottomNavigationBar: SessionTabUtils.bottomNavigationBar(
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
  final MetconSessionDescription metconSessionDescription;

  const MetconSessionCard({Key? key, required this.metconSessionDescription})
      : super(key: key);

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
                          .toHumanWithTime(),
                    ),
                    Defaults.sizedBox.vertical.normal,
                    Text(
                      metconSessionDescription.metconDescription.metcon.name,
                      style: const TextStyle(fontSize: 20),
                    ),
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
