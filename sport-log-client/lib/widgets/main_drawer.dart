import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/data_provider/syncing.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    Key? key,
    required this.selectedRoute,
  }) : super(key: key);

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final user = UserState.instance.currentUser!;
    final lastSync = DownSync.instance.lastSync;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.username),
            accountEmail: Text(user.email),
          ),
          ListTile(
            title: const Text('Workout'),
            leading: const Icon(CustomIcons.dumbbellRotated),
            onTap: () {
              Nav.changeNamed(context, Routes.workout);
            },
            selected: selectedRoute == Routes.workout,
          ),
          const ListTile(
            title: Text('Training Plan'),
            leading: Icon(CustomIcons.plan),
          ),
          ListTile(
            title: const Text('Server Actions'),
            leading: const Icon(Icons.play_circle_fill_sharp),
            onTap: () {
              Nav.changeNamed(context, Routes.actions);
            },
            selected: selectedRoute == Routes.actions,
          ),
          ExpansionTile(
            title: const Text('Primitives'),
            initiallyExpanded: true,
            children: [
              ListTile(
                title: const Text('Movements'),
                leading: const Icon(Icons.apps),
                onTap: () => Nav.changeNamed(context, Routes.movements),
                selected: selectedRoute == Routes.movements,
              ),
              const ListTile(
                title: Text('Routes'),
                leading: Icon(Icons.map_sharp),
              ),
              ListTile(
                title: const Text('CrossFit – Metcons'),
                leading: const Icon(CustomIcons.heart),
                selected: selectedRoute == Routes.metconOverview,
                onTap: () => Nav.changeNamed(context, Routes.metconOverview),
              ),
            ],
          ),
          const Spacer(),
          ListTile(
            title: Text(lastSync == null
                ? 'No sync done yet.'
                : 'Last sync: ' + dateTimeFull.format(lastSync)),
            trailing: IconButton(
              color: secondaryVariantOf(context),
              icon: const Icon(Icons.sync_sharp),
              // TODO: trigger sync on button press
              onPressed: null,
            ),
          ),
          ListTile(
            title: const Text('Logout'),
            trailing: IconButton(
              color: secondaryVariantOf(context),
              icon: const Icon(Icons.logout_sharp),
              onPressed: () {
                context.read<AuthenticationBloc>().add(const LogoutEvent());
                Nav.changeNamed(context, Routes.landing);
              },
            ),
          ),
        ],
      ),
    );
  }
}
