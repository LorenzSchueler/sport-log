import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
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
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            ListTile(
              title: const Text('Workout Tracking'),
              leading: Icon(
                AppIcons.dumbbell,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onTap: () {
                Navigator.of(context).newBase(Routes.timelineOverview);
              },
              selected: selectedRoute == Routes.timelineOverview,
            ),
            ListTile(
              title: const Text('Movements'),
              leading: Icon(
                AppIcons.exercise,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onTap: () =>
                  Navigator.of(context).newBase(Routes.movementOverview),
              selected: selectedRoute == Routes.movementOverview,
            ),
            ListTile(
              leading: Icon(
                AppIcons.stopwatch,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: const Text('Timer'),
              onTap: () => Navigator.of(context).newBase(Routes.timer),
              selected: selectedRoute == Routes.timer,
            ),
            ListTile(
              leading: Icon(
                AppIcons.map,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: const Text('Map'),
              onTap: () => Navigator.of(context).newBase(Routes.map),
              selected: selectedRoute == Routes.map,
            ),
            ListTile(
              leading: Icon(
                AppIcons.fileDownload,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: const Text('Offline Maps'),
              onTap: () => Navigator.of(context).newBase(Routes.offlineMaps),
              selected: selectedRoute == Routes.offlineMaps,
            ),
            ListTile(
              leading: Icon(
                AppIcons.heartbeat,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: const Text('Heart Rate'),
              onTap: () => Navigator.of(context).newBase(Routes.heartRate),
              selected: selectedRoute == Routes.heartRate,
            ),
            ListTile(
              leading: Icon(
                AppIcons.playCircle,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: const Text('Server Actions'),
              onTap: () =>
                  Navigator.of(context).newBase(Routes.platformOverview),
              selected: selectedRoute == Routes.platformOverview,
            ),
            ListTile(
              leading: Icon(
                AppIcons.settings,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: const Text('Settings'),
              onTap: () => Navigator.of(context).newBase(Routes.settings),
              selected: selectedRoute == Routes.settings,
            ),
            const Spacer(),
            Consumer2<Sync, Settings>(
              builder: (context, sync, settings, _) {
                String title;
                if (sync.isSyncing) {
                  title = 'Syncing...';
                } else if (settings.lastSync == null) {
                  title = 'No syncs yet';
                } else {
                  title = 'Last sync: ${settings.lastSync!.toHumanDateTime()}';
                }
                return ListTile(
                  title: Text(title),
                  trailing: SpinningSync(
                    color: Theme.of(context).colorScheme.errorContainer,
                    onPressed: settings.syncEnabled && !sync.isSyncing
                        ? () => sync.sync(
                              onNoInternet: () => showNoInternetToast(context),
                            )
                        : null,
                    isSpinning: sync.isSyncing,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
