import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';

final _dataProvider = MovementDescriptionDataProvider();

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
    _logger.d('Updating movement page');
    final movementDescriptions = await _dataProvider.getNonDeleted();
    setState(() => _movementDescriptions = movementDescriptions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movements"),
      ),
      drawer: MainDrawer(selectedRoute: Routes.movement.overview),
      body: RefreshIndicator(
        onRefresh: _dataProvider.pullFromServer,
        child: _movementDescriptions.isEmpty
            ? const Center(
                child: Text(
                  "looks like there are no movements there yet 😔 \npress ＋ to create a new one",
                  textAlign: TextAlign.center,
                ),
              )
            : Container(
                padding: Defaults.edgeInsets.normal,
                child: ListView.separated(
                  itemBuilder: (_, index) => MovementCard(
                    movementDescription: _movementDescriptions[index],
                  ),
                  separatorBuilder: (_, __) =>
                      Defaults.sizedBox.vertical.normal,
                  itemCount: _movementDescriptions.length,
                ),
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
    return GestureDetector(
      onTap: () async {
        if (movementDescription.movement.userId != null) {
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
        } else {
          await showMessageDialog(
            context: context,
            text: "This is a default movement and cannot be edited.",
          );
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      movementDescription.movement.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  Defaults.sizedBox.vertical.normal,
                  Text(movementDescription.movement.dimension.displayName),
                ],
              ),
              if (movementDescription.movement.description != null) ...[
                Defaults.sizedBox.horizontal.big,
                Expanded(
                  child: Text(
                    movementDescription.movement.description!,
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
