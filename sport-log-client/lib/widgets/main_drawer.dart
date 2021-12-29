import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';

import 'spinning_sync.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    Key? key,
    required this.selectedRoute,
  }) : super(key: key);

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final user = UserState.instance.currentUser!;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.username),
            accountEmail: Text(user.email),
          ),
          ListTile(
            title: const Text('Workout Tracking'),
            leading: const Icon(CustomIcons.dumbbellRotated),
            onTap: () {
              Nav.changeNamed(context, Routes.timeline.overview);
            },
            selected: selectedRoute == Routes.timeline.overview,
          ),
          ListTile(
            title: Text('Training Plan',
                style: TextStyle(color: disabledColorOf(context))),
            leading: const Icon(CustomIcons.plan),
          ),
          ListTile(
            title: Text('Server Actions',
                style: TextStyle(color: disabledColorOf(context))),
            leading: const Icon(Icons.play_circle_fill_sharp),
          ),
          ExpansionTile(
            title: const Text('Primitives'),
            initiallyExpanded: true,
            children: [
              ListTile(
                title: const Text('Movements'),
                leading: const Icon(CustomIcons.trendingUp),
                onTap: () => Nav.changeNamed(context, Routes.movement.overview),
                selected: selectedRoute == Routes.movement.overview,
              ),
              ListTile(
                title: const Text('CrossFit – Metcons'),
                leading: const Icon(CustomIcons.heart),
                selected: selectedRoute == Routes.metcon.overview,
                onTap: () => Nav.changeNamed(context, Routes.metcon.overview),
              ),
            ],
          ),
          const Spacer(),
          Consumer<Sync>(
            builder: (context, sync, _) {
              String title;
              if (sync.isSyncing) {
                title = 'Syncing...';
              } else if (sync.lastSync == null) {
                title = 'No syncs yet';
              } else {
                title = 'Last sync: ' + sync.lastSync!.toHumanWithTime();
              }
              return ListTile(
                title: Text(title),
                trailing: SpinningSync(
                  color: secondaryVariantOf(context),
                  onPressed: sync.isSyncing
                      ? null
                      : () => Sync.instance.sync(
                            onNoInternet: () {
                              showSimpleToast(
                                  context, 'No Internet connection.');
                            },
                          ),
                  isSpinning: sync.isSyncing,
                ),
              );
            },
          ),
          Consumer<Sync>(
            builder: (context, sync, _) => ListTile(
              title: const Text('Logout'),
              trailing: IconButton(
                color: secondaryVariantOf(context),
                icon: const Icon(Icons.logout_sharp),
                onPressed: sync.isSyncing
                    ? null
                    : () {
                        context
                            .read<AuthenticationBloc>()
                            .add(const LogoutEvent());
                        Nav.changeNamed(context, Routes.landing);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
