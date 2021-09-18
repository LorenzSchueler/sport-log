import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
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
            children: [
              ListTile(
                title: const Text('Movements'),
                leading: const Icon(Icons.apps),
                onTap: () {
                  Nav.changeNamed(context, Routes.movements);
                },
                selected: selectedRoute == Routes.movements,
              ),
              const ListTile(
                title: Text('Routes'),
                leading: Icon(Icons.map_sharp),
              ),
              const ListTile(
                title: Text('CrossFit – Metcons'),
                leading: Icon(CustomIcons.heart),
              ),
            ],
          ),
          const Spacer(),
          ListTile(
            title: const Text('Logout'),
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
