import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/picker/picker.dart';

class SelectRouteButton extends StatelessWidget {
  const SelectRouteButton({
    required this.selectedRoute,
    required this.updateRoute,
    super.key,
  });

  final Route? selectedRoute;
  final void Function(Route? route) updateRoute;

  Future<void> selectRoute(BuildContext context) async {
    final route = await showRoutePicker(
      context: context,
      selectedRoute: selectedRoute,
    );
    if (route == null) {
      return;
    } else if (route.id == selectedRoute?.id) {
      updateRoute(null);
    } else {
      updateRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: () => selectRoute(context),
      child: const Icon(AppIcons.route),
    );
  }
}
