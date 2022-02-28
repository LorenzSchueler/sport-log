import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/approve_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';

final _dataProvider = MovementDescriptionDataProvider.instance;

class MovementsPage extends StatefulWidget {
  const MovementsPage({Key? key}) : super(key: key);

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _logger = Logger('MovementsPage');
  List<MovementDescription> _movementDescriptions = [];

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
    _logger.d('Updating movement page');
    final movementDescriptions = await _dataProvider.getNonDeleted();
    setState(() => _movementDescriptions = movementDescriptions);
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
        title: const Text("Movements"),
      ),
      drawer: MainDrawer(selectedRoute: Routes.movement.overview),
      body: RefreshIndicator(
        onRefresh: _pullFromServer,
        child: _movementDescriptions.isEmpty
            ? const Center(
                child: Text(
                  "looks like there are no movements there yet 😔 \npress ＋ to create a new one",
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemBuilder: (_, index) => MovementCard(
                  movementDescription: _movementDescriptions[index],
                ),
                itemCount: _movementDescriptions.length,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(AppIcons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, Routes.movement.edit);
        },
      ),
    );
  }
}

class MovementCard extends StatelessWidget {
  final MovementDescription movementDescription;

  const MovementCard({Key? key, required this.movementDescription})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTileCard(
      leading: CircleAvatar(child: Text(movementDescription.movement.name[0])),
      title: Text(movementDescription.movement.name),
      subtitle: Text(movementDescription.movement.dimension.displayName),
      children: [
        if (movementDescription.movement.description != null) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(movementDescription.movement.description!),
          ),
        ],
        if (movementDescription.movement.userId != null) ...[
          const Divider(),
          ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              if (!movementDescription.hasReference)
                IconButton(
                  onPressed: () async =>
                      await _dataProvider.deleteSingle(movementDescription),
                  icon: const Icon(AppIcons.delete),
                ),
              IconButton(
                onPressed: () async {
                  if (movementDescription.hasReference) {
                    final bool? approved = await showApproveDialog(
                      context,
                      'Warning',
                      'Changes will be reflected in existing workouts.',
                    );
                    if (approved == null || !approved) return;
                  }
                  await Navigator.pushNamed(
                    context,
                    Routes.movement.edit,
                    arguments: movementDescription,
                  );
                },
                icon: const Icon(AppIcons.edit),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
