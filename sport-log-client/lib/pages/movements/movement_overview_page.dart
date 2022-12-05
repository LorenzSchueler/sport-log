import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MovementsPage extends StatelessWidget {
  MovementsPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<MovementDescription, void,
              MovementDescriptionDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: MovementDescriptionDataProvider(),
          entityAccessor: (dataProvider) =>
              (_, __, ___, search) => dataProvider.getByName(search),
          recordAccessor: (_) => () async {},
          loggerName: "MovementsPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSearch
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (name) => dataProvider.search = name,
                    decoration: Theme.of(context).textFormFieldDecoration,
                  )
                : const Text("Movements"),
            actions: [
              IconButton(
                onPressed: () {
                  dataProvider.search = dataProvider.isSearch ? null : "";
                  if (dataProvider.isSearch) {
                    _searchBar.requestFocus();
                  }
                },
                icon: Icon(
                  dataProvider.isSearch ? AppIcons.close : AppIcons.search,
                ),
              ),
            ],
          ),
          drawer: MainDrawer(selectedRoute: Routes.movement.overview),
          body: Consumer<Sync>(
            builder: (context, sync, _) {
              return RefreshIndicator(
                onRefresh: () => sync.sync(
                  onNoInternet: () => showNoInternetToast(context),
                ),
                child: dataProvider.entities.isEmpty
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
                            movementDescription: dataProvider.entities[index],
                          ),
                          separatorBuilder: (_, __) =>
                              Defaults.sizedBox.vertical.normal,
                          itemCount: dataProvider.entities.length,
                        ),
                      ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () async {
              await Navigator.pushNamed(context, Routes.movement.edit);
            },
          ),
        ),
      ),
    );
  }
}

class MovementCard extends StatelessWidget {
  const MovementCard({required this.movementDescription, super.key});

  final MovementDescription movementDescription;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (movementDescription.movement.userId != null) {
          if (movementDescription.hasReference) {
            final approved = await showApproveDialog(
              context: context,
              title: 'Warning',
              text: 'Changes will be reflected in existing workouts.',
            );
            if (!approved) return;
          }
          // ignore: use_build_context_synchronously
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
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Defaults.sizedBox.vertical.normal,
                  Text("${movementDescription.movement.dimension}"),
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
