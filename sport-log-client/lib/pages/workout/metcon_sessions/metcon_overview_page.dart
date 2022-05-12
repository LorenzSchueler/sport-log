import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class MetconsPage extends StatefulWidget {
  const MetconsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MetconsPageState();
}

class _MetconsPageState extends State<MetconsPage> {
  final _logger = Logger('MetconsPage');
  final _searchBar = FocusNode();
  final _dataProvider = MetconDescriptionDataProvider();
  List<MetconDescription> _metconDescriptions = [];
  String? _metconName;

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
    _logger.d('Updating metcon page filtered by name: $_metconName');
    final metconDescriptions = await _dataProvider.getByMetconName(_metconName);
    setState(() => _metconDescriptions = metconDescriptions);
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: _metconName == null
              ? const Text("Metcons")
              : TextFormField(
                  focusNode: _searchBar,
                  onChanged: (name) {
                    _metconName = name;
                    _update();
                  },
                  decoration: Theme.of(context).textFormFieldDecoration,
                ),
          actions: [
            IconButton(
              onPressed: () {
                _metconName = _metconName == null ? "" : null;
                _update();
                if (_metconName != null) {
                  _searchBar.requestFocus();
                }
              },
              icon: Icon(
                _metconName != null ? AppIcons.close : AppIcons.search,
              ),
            ),
            IconButton(
              onPressed: () =>
                  Navigator.of(context).newBase(Routes.metcon.sessionOverview),
              icon: const Icon(AppIcons.notes),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _dataProvider.pullFromServer,
          child: _metconDescriptions.isEmpty
              ? const Center(
                  child: Text(
                    "looks like there are no metcons there yet 😔 \npress ＋ to create a new one",
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  padding: Defaults.edgeInsets.normal,
                  child: ListView.separated(
                    itemBuilder: (_, index) => MetconCard(
                      metconDescription: _metconDescriptions[index],
                    ),
                    separatorBuilder: (_, __) =>
                        Defaults.sizedBox.vertical.normal,
                    itemCount: _metconDescriptions.length,
                  ),
                ),
        ),
        bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
          context,
          SessionsPageTab.metcon,
        ),
        drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
        floatingActionButton: FloatingActionButton(
          child: const Icon(AppIcons.add),
          onPressed: () => Navigator.pushNamed(context, Routes.metcon.edit),
        ),
      ),
    );
  }
}

class MetconCard extends StatelessWidget {
  final MetconDescription metconDescription;

  const MetconCard({Key? key, required this.metconDescription})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.metcon.details,
        arguments: metconDescription,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metconDescription.metcon.name,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Defaults.sizedBox.vertical.normal,
              Text(
                metconDescription.typeLengthDescription,
              ),
              Defaults.sizedBox.vertical.normal,
              Text(
                metconDescription.moves
                    .map((mmd) => mmd.movement.name)
                    .join(' • '),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
