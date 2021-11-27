import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/route_data_provider.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/routes.dart';

Future<Route?> showRoutePickerDialog(
  BuildContext context, {
  bool dismissable = true,
}) async {
  final _dataProvider = RouteDataProvider();
  final _routes = await _dataProvider.getNonDeleted();
  return showDialog<Route>(
    builder: (_) => RoutePickerDialog(_routes),
    barrierDismissible: dismissable,
    context: context,
  );
}

class RoutePickerDialog extends StatelessWidget {
  final List<Route> _routes;

  const RoutePickerDialog(this._routes, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(clipBehavior: Clip.antiAlias, child: _routeList);
  }

  Widget get _routeList {
    if (_routes.isEmpty) {
      return const Center(child: Text('No routes here.'));
    }
    return Scrollbar(
      child: ListView.separated(
        itemBuilder: _routeBuilder,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _routes.length,
      ),
    );
  }

  Widget _routeBuilder(BuildContext context, int index) {
    final route = _routes[index];

    return ListTile(
      title: Text(route.name),
      onTap: () {
        Navigator.of(context).pop(route);
      },
    );
  }
}
