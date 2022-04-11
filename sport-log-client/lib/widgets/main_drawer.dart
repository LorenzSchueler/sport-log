import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/spinning_sync.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    Key? key,
    required this.selectedRoute,
  }) : super(key: key);

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(Settings.username!),
            accountEmail: Text(Settings.email!),
          ),
          ListTile(
            title: const Text('Workout Tracking'),
            leading: Icon(
              AppIcons.dumbbell,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onTap: () {
              Navigator.of(context).newBase(Routes.timeline.overview);
            },
            selected: selectedRoute == Routes.timeline.overview,
          ),
          ListTile(
            title: const Text('Movements'),
            leading: Icon(
              AppIcons.exercise,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onTap: () =>
                Navigator.of(context).newBase(Routes.movement.overview),
            selected: selectedRoute == Routes.movement.overview,
          ),
          ListTile(
            leading: Icon(
              AppIcons.timer,
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
                Navigator.of(context).newBase(Routes.action.platformOverview),
            selected: selectedRoute == Routes.action.platformOverview,
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
          Consumer<Sync>(
            builder: (context, sync, _) {
              String title;
              if (sync.isSyncing) {
                title = 'Syncing...';
              } else if (Settings.lastSync == null) {
                title = 'No syncs yet';
              } else {
                title = 'Last sync: ' + Settings.lastSync!.toHumanDateTime();
              }
              return ListTile(
                title: Text(title),
                trailing: SpinningSync(
                  color: Theme.of(context).colorScheme.errorContainer,
                  onPressed: Settings.syncEnabled && !sync.isSyncing
                      ? () => Sync.instance.sync(
                            onNoInternet: () {
                              showSimpleToast(
                                context,
                                'No Internet connection.',
                              );
                            },
                          )
                      : null,
                  isSpinning: sync.isSyncing,
                ),
              );
            },
          ),
          Consumer<Sync>(
            builder: (context, sync, _) => ListTile(
              title: const Text('Logout'),
              trailing: IconButton(
                color: Theme.of(context).colorScheme.error,
                icon: const Icon(AppIcons.logout),
                onPressed: sync.isSyncing
                    ? null
                    : () async {
                        await Account.logout();
                        Navigator.of(context).newBase(Routes.landing);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
