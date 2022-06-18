import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class PlatformNotSupportedPage extends StatelessWidget {
  const PlatformNotSupportedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(),
        drawer: const MainDrawer(selectedRoute: Routes.map),
        body: const Center(
          child: Text("The selected page is not supported on you platform."),
        ),
      ),
    );
  }
}
