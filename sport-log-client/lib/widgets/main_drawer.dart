import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/snackbar.dart';
import 'package:sport_log/widgets/spinning_sync.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({required this.selectedRoute, super.key});

  final String selectedRoute;

  /// Routes that select the Workout Tracking destination.
  static const _workoutTrackingRoutes = {
    Routes.timelineOverview,
    Routes.strengthOverview,
    Routes.metconSessionOverview,
    Routes.metconOverview,
    Routes.cardioOverview,
    Routes.routeOverview,
    Routes.wodOverview,
    Routes.diaryOverview,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(
      builder: (context, settings, _) {
        final destinations = [
          (
            Routes.defaultWorkoutTracking,
            'Workout Tracking',
            AppIcons.dumbbell,
          ),
          (Routes.movementOverview, 'Movements', AppIcons.movement),
          (Routes.timer, 'Timer', AppIcons.stopwatch),
          (Routes.map, 'Map', AppIcons.map),
          (Routes.offlineMaps, 'Offline Maps', AppIcons.fileDownload),
          (Routes.heartRate, 'Heart Rate', AppIcons.heartbeat),
          if (settings.accountCreated)
            (Routes.platformOverview, 'Server Actions', AppIcons.playCircle),
          (Routes.settings, 'Settings', AppIcons.settings),
        ];
        return NavigationDrawer(
          selectedIndex: destinations.indexWhere(
            (d) =>
                d.$1 == selectedRoute ||
                d.$1 == Routes.defaultWorkoutTracking &&
                    _workoutTrackingRoutes.contains(selectedRoute),
          ),
          onDestinationSelected: (index) =>
              Navigator.of(context).newBase(destinations[index].$1),
          header: const DrawerHeader(
            child: Column(
              children: [
                Icon(AppIcons.plan, size: 90),
                Text("Sport Log", style: TextStyle(fontSize: 30)),
              ],
            ),
          ),
          footer: settings.accountCreated
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: Consumer<Sync>(
                      builder: (context, sync, _) => Row(
                        children: [
                          Text(
                            sync.isSyncing
                                ? 'Syncing...'
                                : settings.epochMap == null
                                ? 'No syncs yet'
                                : 'Last sync: ${settings.epochMap!.lastSync.humanTodayTimeOrDate}',
                          ),
                          const Spacer(),
                          SpinningSync(
                            color: AppColors.of(context).success,
                            onPressed: settings.syncEnabled && !sync.isSyncing
                                ? () => sync.sync(
                                    onNoInternet: showNoInternetSnackBar,
                                  )
                                : null,
                            isSpinning: sync.isSyncing,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
          children: [
            for (final (_, label, icon) in destinations)
              NavigationDrawerDestination(icon: Icon(icon), label: Text(label)),
          ],
        );
      },
    );
  }
}
