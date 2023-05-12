import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

class MetconsPage extends StatelessWidget {
  MetconsPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<MetconDescription, void,
              MetconDescriptionDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: MetconDescriptionDataProvider(),
          entityAccessor: (dataProvider) =>
              (_, __, ___, search) => dataProvider.getByMetconName(search),
          recordAccessor: (_) => () async {},
          loggerName: "MetconsPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSearch
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (name) => dataProvider.search = name,
                    decoration: Theme.of(context).textFormFieldDecoration,
                  )
                : const Text("Metcons"),
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
              IconButton(
                onPressed: () =>
                    Navigator.of(context).newBase(Routes.metconSessionOverview),
                icon: const Icon(AppIcons.notes),
              ),
            ],
          ),
          body: SyncRefreshIndicator(
            child: dataProvider.entities.isEmpty
                ? const RefreshableNoEntriesText(
                    text:
                        "Looks like there are no metcons there yet 😔\nPress ＋ to create a new one",
                  )
                : Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: ListView.separated(
                      itemBuilder: (_, index) => MetconCard(
                        metconDescription: dataProvider.entities[index],
                      ),
                      separatorBuilder: (_, __) =>
                          Defaults.sizedBox.vertical.normal,
                      itemCount: dataProvider.entities.length,
                    ),
                  ),
          ),
          bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
            context: context,
            sessionsPageTab: SessionsPageTab.metcon,
          ),
          drawer: const MainDrawer(selectedRoute: Routes.metconOverview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, Routes.metconEdit),
          ),
        ),
      ),
    );
  }
}

class MetconCard extends StatelessWidget {
  const MetconCard({required this.metconDescription, super.key});

  final MetconDescription metconDescription;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.metconDetails,
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
                style: Theme.of(context).textTheme.titleMedium,
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
