
import 'package:flutter/material.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/helpers/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    Key? key,
    required this.selectedRoute,
  }) : super(key: key);

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: null,
          ),
          ListTile(
            title: const Text("Movements"),
            leading: const Icon(Icons.apps),
            onTap: () {
              Nav.changeNamed(context, Routes.movements);
            },
            selected: selectedRoute == Routes.movements,
          ),
          ListTile(
            title: const Text("Workout"),
            leading: const Icon(CustomIcons.dumbbell_rotated),
            onTap: () {
              Nav.changeNamed(context, Routes.workout);
            },
            selected: selectedRoute == Routes.workout,
          ),
          ListTile(
              title: const Text("Logs"),
              leading: const Icon(Icons.calendar_today),
              onTap: () {
                Nav.changeNamed(context, Routes.logs);
              },
              selected: selectedRoute == Routes.logs
          ),
          ListTile(
            title: const Text("Syncing"),
            leading: const Icon(Icons.sync),
            onTap: () {
              Nav.changeNamed(context, Routes.syncing);
            },
            selected: selectedRoute == Routes.syncing
          ),
          const Spacer(),
          ListTile(
            title: const Text("Logout"),
            leading: const Icon(Icons.logout),
            onTap: () {
              context.read<AuthenticationBloc>().add(const LogoutEvent());
              Nav.changeNamed(context, Routes.landing);
            },
          ),
        ],
      ),
    );
  }
}