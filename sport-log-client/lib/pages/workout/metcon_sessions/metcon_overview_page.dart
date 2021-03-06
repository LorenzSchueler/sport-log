import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/overview_data_provider.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class MetconsPage extends StatelessWidget {
  MetconsPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<MetconDescription, void,
              MetconDescriptionDataProvider, String>>(
        create: (_) => OverviewDataProvider(
          dataProvider: MetconDescriptionDataProvider(),
          entityAccessor: (dataProvider) =>
              (_, __, metconName) => dataProvider.getByMetconName(metconName),
          recordAccessor: (_) => () async {},
          loggerName: "MetconsPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSelected
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (name) => dataProvider.selected = name,
                    decoration: Theme.of(context).textFormFieldDecoration,
                  )
                : const Text("Metcons"),
            actions: [
              IconButton(
                onPressed: () {
                  dataProvider.selected = dataProvider.isSelected ? null : "";
                  if (dataProvider.isSelected) {
                    _searchBar.requestFocus();
                  }
                },
                icon: Icon(
                  dataProvider.isSelected ? AppIcons.close : AppIcons.search,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context)
                    .newBase(Routes.metcon.sessionOverview),
                icon: const Icon(AppIcons.notes),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: dataProvider.pullFromServer,
            child: dataProvider.entities.isEmpty
                ? const Center(
                    child: Text(
                      "looks like there are no metcons there yet ???? \npress ??? to create a new one",
                      textAlign: TextAlign.center,
                    ),
                  )
                : Container(
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
          drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, Routes.metcon.edit),
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
                    .join(' ??? '),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
