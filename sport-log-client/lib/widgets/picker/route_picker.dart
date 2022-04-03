import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/models/cardio/route.dart';

Future<Route?> showRoutePicker({
  required BuildContext context,
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
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: _routes.isEmpty
          ? const Center(child: Text('No routes here.'))
          : Scrollbar(
              child: ListView.separated(
                itemBuilder: (context, index) => ListTile(
                  title: Text(_routes[index].name),
                  onTap: () => Navigator.pop(context, _routes[index]),
                ),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: _routes.length,
              ),
            ),
    );
  }
}
