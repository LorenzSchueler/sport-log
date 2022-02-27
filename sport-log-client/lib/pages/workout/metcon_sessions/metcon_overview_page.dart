import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
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
    _update();
  }

  Future<void> _update() async {
    final mds = await _dataProvider.getNonDeleted();
    setState(() {
      _metconDescriptions = mds;
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
      body: _content,
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, SessionsPageTab.metcon),
      drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
      floatingActionButton: FloatingActionButton(
        child: const Icon(AppIcons.add),
        onPressed: () => Navigator.pushNamed(context, Routes.metcon.edit),
      ),
    );
  }

  Widget get _content {
    if (_metconDescriptions.isEmpty) {
      return const Center(child: Text('No metcons there.'));
    }
    return ListView.builder(
      itemBuilder: (_, index) =>
          MetconCard(metconDescription: _metconDescriptions[index]),
      itemCount: _metconDescriptions.length,
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
