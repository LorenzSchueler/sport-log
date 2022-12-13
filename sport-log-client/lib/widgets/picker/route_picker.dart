import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';

Future<Route?> showRoutePicker({
  required BuildContext context,
  Route? selectedRoute,
  bool dismissible = true,
}) async {
  return showDialog<Route>(
    builder: (_) => RoutePickerDialog(selectedRoute: selectedRoute),
    barrierDismissible: dismissible,
    context: context,
  );
}

class RoutePickerDialog extends StatefulWidget {
  const RoutePickerDialog({
    required this.selectedRoute,
    super.key,
  });

  final Route? selectedRoute;

  @override
  State<RoutePickerDialog> createState() => _RoutePickerDialogState();
}

class _RoutePickerDialogState extends State<RoutePickerDialog> {
  final _dataProvider = RouteDataProvider();
  late final StreamSubscription<bool> _keyboardSubscription =
      KeyboardVisibilityController().onChange.listen((isVisible) {
    if (!isVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  });

  List<Route> _routes = [];
  String _search = '';

  @override
  void initState() {
    _update('');
    super.initState();
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  Future<void> _update(String newSearch) async {
    final routes = await _dataProvider.getByName(newSearch.trim());
    if (widget.selectedRoute != null) {
      final index =
          routes.indexWhere((route) => route.id == widget.selectedRoute!.id);
      if (index >= 0) {
        routes.insert(0, routes.removeAt(index));
      }
    }
    if (mounted) {
      setState(() {
        _routes = routes;
        _search = newSearch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _searchBar,
          const Divider(
            height: 1,
            thickness: 2,
          ),
          Expanded(child: _routeList)
        ],
      ),
    );
  }

  Widget get _searchBar {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: TextFormField(
        autofocus: true,
        initialValue: _search,
        onChanged: _update,
        decoration: Theme.of(context).textFormFieldDecoration.copyWith(
              labelText: 'Search',
              prefixIcon: const Icon(AppIcons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.cardio.routeEdit,
                      ),
                      icon: const Icon(AppIcons.add),
                    )
                  : null,
            ),
      ),
    );
  }

  Widget get _routeList {
    return _routes.isEmpty
        ? const Center(child: Text('No routes here.'))
        : Scrollbar(
            child: ListView.separated(
              itemBuilder: _routeBuilder,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _routes.length,
            ),
          );
  }

  Widget _routeBuilder(BuildContext context, int index) {
    final route = _routes[index];
    final selected = route.id == widget.selectedRoute?.id;

    return ListTile(
      title: Text(route.name),
      onTap: () {
        Navigator.pop(context, route);
      },
      selected: selected,
      trailing: selected ? const Icon(AppIcons.check) : null,
    );
  }
}
