import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/widgets/spinning_sync.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    required this.selectedRoute,
    super.key,
  });

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;
    return SafeArea(
      child: Drawer(
        child: Consumer<Settings>(
          builder: (context, settings, _) {
            return Column(
              children: [
                const DrawerHeader(
                  child: Column(
                    children: [
                      Icon(
                        AppIcons.plan,
                        size: 90,
                      ),
                      Text(
                        "Sport Log",
                        style: TextStyle(fontSize: 30),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('Workout Tracking'),
                        leading:
                            Icon(AppIcons.dumbbell, color: onBackgroundColor),
                        onTap: () => Navigator.of(context)
                            .newBase(Routes.timelineOverview),
                        selected: selectedRoute == Routes.timelineOverview,
                      ),
                      ListTile(
                        title: const Text('Movements'),
                        leading:
                            Icon(AppIcons.movement, color: onBackgroundColor),
                        onTap: () => Navigator.of(context)
                            .newBase(Routes.movementOverview),
                        selected: selectedRoute == Routes.movementOverview,
                      ),
                      ListTile(
                        leading:
                            Icon(AppIcons.stopwatch, color: onBackgroundColor),
                        title: const Text('Timer'),
                        onTap: () =>
                            Navigator.of(context).newBase(Routes.timer),
                        selected: selectedRoute == Routes.timer,
                      ),
                      ListTile(
                        leading: Icon(AppIcons.map, color: onBackgroundColor),
                        title: const Text('Map'),
                        onTap: () => Navigator.of(context).newBase(Routes.map),
                        selected: selectedRoute == Routes.map,
                      ),
                      ListTile(
                        leading: Icon(
                          AppIcons.fileDownload,
                          color: onBackgroundColor,
                        ),
                        title: const Text('Offline Maps'),
                        onTap: () =>
                            Navigator.of(context).newBase(Routes.offlineMaps),
                        selected: selectedRoute == Routes.offlineMaps,
                      ),
                      ListTile(
                        leading:
                            Icon(AppIcons.heartbeat, color: onBackgroundColor),
                        title: const Text('Heart Rate'),
                        onTap: () =>
                            Navigator.of(context).newBase(Routes.heartRate),
                        selected: selectedRoute == Routes.heartRate,
                      ),
                      if (settings.accountCreated)
                        ListTile(
                          leading: Icon(
                            AppIcons.playCircle,
                            color: onBackgroundColor,
                          ),
                          title: const Text('Server Actions'),
                          onTap: () => Navigator.of(context)
                              .newBase(Routes.platformOverview),
                          selected: selectedRoute == Routes.platformOverview,
                        ),
                      ListTile(
                        leading:
                            Icon(AppIcons.settings, color: onBackgroundColor),
                        title: const Text('Settings'),
                        onTap: () =>
                            Navigator.of(context).newBase(Routes.settings),
                        selected: selectedRoute == Routes.settings,
                      ),
                    ],
                  ),
                ),
                if (settings.accountCreated)
                  Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: Consumer<Sync>(
                      builder: (context, sync, _) => Row(
                        children: [
                          Text(
                            sync.isSyncing
                                ? 'Syncing...'
                                : settings.lastSync == null
                                    ? 'No syncs yet'
                                    : 'Last sync: ${settings.lastSync!.toHumanDateTime()}',
                          ),
                          const Spacer(),
                          SpinningSync(
                            color: Theme.of(context).colorScheme.errorContainer,
                            onPressed: settings.syncEnabled && !sync.isSyncing
                                ? () => sync.sync(
                                      onNoInternet: () =>
                                          showNoInternetToast(context),
                                    )
                                : null,
                            isSpinning: sync.isSyncing,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
