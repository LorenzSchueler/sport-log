import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

class MovementOverviewPage extends StatelessWidget {
  MovementOverviewPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child:
          ProviderConsumer<
            OverviewDataProvider<
              MovementDescription,
              void,
              MovementDescriptionDataProvider,
              void
            >
          >(
            create: (_) => OverviewDataProvider(
              dataProvider: MovementDescriptionDataProvider(),
              entityAccessor: (dataProvider) =>
                  (_, __, ___, search) => dataProvider.getByName(search),
              recordAccessor: (_) => () async {},
              loggerName: "MovementsPage",
            ),
            builder: (_, dataProvider, __) => Scaffold(
              appBar: AppBar(
                title: dataProvider.isSearch
                    ? TextFormField(
                        focusNode: _searchBar,
                        onChanged: (name) => dataProvider.search = name,
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
              drawer: const MainDrawer(selectedRoute: Routes.movementOverview),
              body: SyncRefreshIndicator(
                child: dataProvider.entities.isEmpty
                    ? const RefreshableNoEntriesText(
                        text:
                            "Looks like there are no movements there yet 😔\nPress ＋ to create a new one",
                      )
                    : Padding(
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
              ),
              floatingActionButton: FloatingActionButton(
                child: const Icon(AppIcons.add),
                onPressed: () async {
                  await Navigator.pushNamed(context, Routes.movementEdit);
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
        if (!movementDescription.movement.isDefaultMovement) {
          if (movementDescription.hasReference) {
            final approved = await showApproveDialog(
              context: context,
              title: 'Warning',
              text: 'Changes will be reflected in existing workouts.',
            );
            if (!approved) return;
          }
          if (context.mounted) {
            await Navigator.pushNamed(
              context,
              Routes.movementEdit,
              arguments: movementDescription,
            );
          }
        } else {
          await showMessageDialog(
            context: context,
            title: "Default Movement",
            text:
                "${movementDescription.movement.name} is a default movement and cannot be edited.",
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
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Defaults.sizedBox.vertical.normal,
                  Text(movementDescription.movement.dimension.name),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
