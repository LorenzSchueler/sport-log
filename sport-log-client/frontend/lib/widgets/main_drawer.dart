
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';
import 'package:sport_log/helpers/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: null,
          ),
          ListTile(
            title: const Text("Workout"),
            leading: const Icon(CustomIcons.dumbbell_rotated),
            onTap: () {

            },
          ),
          ListTile(
            title: const Text("Syncing"),
            leading: const Icon(Icons.sync),
            onTap: () {
              Nav.changeNamed(context, Routes.syncing);
            },
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