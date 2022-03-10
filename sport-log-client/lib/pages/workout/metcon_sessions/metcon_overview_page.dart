import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MetconsPage extends StatefulWidget {
  const MetconsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MetconsPageState();
}

class _MetconsPageState extends State<MetconsPage> {
  final _logger = Logger('MetconsPage');
  final _dataProvider = MetconDescriptionDataProvider.instance;
  List<MetconDescription> _metconDescriptions = [];

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
    _logger.d('Updating route page');
    final metconDescriptions = await _dataProvider.getNonDeleted();
    setState(() => _metconDescriptions = metconDescriptions);
  }

  Future<void> _pullFromServer() async {
    await _dataProvider.pullFromServer().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Metcons"),
        actions: [
          IconButton(
            onPressed: () =>
                Nav.newBase(context, Routes.metcon.sessionOverview),
            icon: const Icon(AppIcons.notes),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _pullFromServer,
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
                  itemBuilder: (_, index) =>
                      MetconCard(metconDescription: _metconDescriptions[index]),
                  separatorBuilder: (_, __) =>
                      Defaults.sizedBox.vertical.normal,
                  itemCount: _metconDescriptions.length,
                ),
              ),
      ),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.metcon),
      drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
      floatingActionButton: FloatingActionButton(
        child: const Icon(AppIcons.add),
        onPressed: () => Navigator.pushNamed(context, Routes.metcon.edit),
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
        child: ListTile(
          title: Text(metconDescription.metcon.name ?? 'Unnamed'),
          subtitle: Text(
            metconDescription.moves.map((mmd) => mmd.movement.name).join(' • '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
