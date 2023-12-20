import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/wod_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/wod/wod.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter.dart';
import 'package:sport_log/pages/workout/overview_card.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

class WodOverviewPage extends StatelessWidget {
  WodOverviewPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<Wod, void, WodDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: WodDataProvider(),
          entityAccessor: (dataProvider) => (start, end, _, search) =>
              dataProvider.getByTimerangeAndDescription(
                from: start,
                until: end,
                description: search,
              ),
          recordAccessor: (_) => () async {},
          loggerName: "WodPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSearch
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (comment) => dataProvider.search = comment,
                  )
                : const Text("Wod"),
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
            bottom: DateFilter(
              initialState: dataProvider.dateFilter,
              onFilterChanged: (dateFilter) =>
                  dataProvider.dateFilter = dateFilter,
            ),
          ),
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              SyncRefreshIndicator(
                child: dataProvider.entities.isEmpty
                    ? RefreshableNoEntriesText(
                        text: SessionsPageTab.wod.noEntriesText,
                      )
                    : Padding(
                        padding: Defaults.edgeInsets.normal,
                        child: ListView.separated(
                          itemBuilder: (_, index) => WodCard(
                            wod: dataProvider.entities[index],
                          ),
                          separatorBuilder: (_, __) =>
                              Defaults.sizedBox.vertical.normal,
                          itemCount: dataProvider.entities.length,
                        ),
                      ),
              ),
              if (dataProvider.isLoading)
                const Positioned(
                  top: 40,
                  child: RefreshProgressIndicator(),
                ),
            ],
          ),
          bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
            context: context,
            sessionsPageTab: SessionsPageTab.wod,
          ),
          drawer: const MainDrawer(selectedRoute: Routes.wodOverview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, Routes.wodEdit),
          ),
        ),
      ),
    );
  }
}

class WodCard extends StatelessWidget {
  const WodCard({required this.wod, super.key});

  final Wod wod;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      datetime: wod.date,
      left: const [],
      right: const [],
      comments: wod.description,
      onTap: () {
        Navigator.pushNamed(context, Routes.wodEdit, arguments: wod);
      },
      dateOnly: true,
    );
  }
}
