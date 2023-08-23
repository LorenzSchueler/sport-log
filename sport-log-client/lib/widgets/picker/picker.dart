import 'dart:async';

import 'package:flutter/material.dart' hide Action, Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/models/action/action.dart';
import 'package:sport_log/models/action/weekday.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/timeline_union.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

class Picker<T> extends StatelessWidget {
  const Picker({
    required this.items,
    required this.selectedItem,
    required this.title,
    required this.compareWith,
    super.key,
  });

  final List<T> items;
  final T? selectedItem;
  final String Function(T) title;
  final Object Function(T) compareWith;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(title(item)),
            selected: selectedItem != null
                ? compareWith(item) == compareWith(selectedItem as T)
                : false,
            onTap: () => Navigator.pop(context, item),
          );
        },
        itemCount: items.length,
        separatorBuilder: (context, _) => const Divider(height: 0),
        shrinkWrap: true,
      ),
    );
  }
}

class PickerWithSearch<T> extends StatefulWidget {
  const PickerWithSearch({
    required this.selectedItem,
    required this.getByName,
    required this.editRoute,
    required this.compareWith,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final T? selectedItem;
  final Future<List<T>> Function(String) getByName;
  final String? editRoute;
  final bool Function(T, T?) compareWith;
  final String Function(T) title;
  final String? Function(T)? subtitle;

  @override
  State<PickerWithSearch<T>> createState() => _PickerWithSearchState<T>();
}

class _PickerWithSearchState<T> extends State<PickerWithSearch<T>> {
  List<T> _items = [];
  String _search = '';

  @override
  void initState() {
    _update('');
    super.initState();
  }

  Future<void> _update(String search) async {
    final items = await widget.getByName(search.trim());
    if (widget.selectedItem != null) {
      final index = items
          .indexWhere((item) => widget.compareWith(item, widget.selectedItem));
      if (index >= 0) {
        items.insert(0, items.removeAt(index));
      }
    }
    if (mounted) {
      setState(() {
        _items = items;
        _search = search;
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
            height: 0,
            thickness: 2,
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Nothing found.'))
                : Scrollbar(
                    child: ListView.separated(
                      itemBuilder: _routeBuilder,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemCount: _items.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget get _searchBar {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        autofocus: true,
        initialValue: _search,
        onChanged: _update,
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: _search.isNotEmpty && widget.editRoute != null
              ? IconButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    widget.editRoute!,
                  ),
                  icon: const Icon(AppIcons.add),
                )
              : null,
        ),
      ),
    );
  }

  Widget _routeBuilder(BuildContext context, int index) {
    final item = _items[index];
    final subtitle =
        widget.subtitle != null ? widget.subtitle!.call(item) : null;

    return ListTile(
      title: Text(widget.title(item)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      selected: widget.compareWith(item, widget.selectedItem),
      onTap: () => Navigator.pop(context, item),
    );
  }
}

Future<Action?> showActionPicker({
  required List<Action> actions,
  required Action? selectedAction,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Action>(
    builder: (_) => Picker<Action>(
      items: actions,
      selectedItem: selectedAction,
      title: (action) => action.name,
      compareWith: (action) => action.id,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<CardioType?> showCardioTypePicker({
  required CardioType? selectedCardioType,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<CardioType>(
    builder: (_) => Picker<CardioType>(
      items: CardioType.values,
      selectedItem: selectedCardioType,
      title: (cardioType) => cardioType.name,
      compareWith: (cardioType) => cardioType.index,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<DateFilterState?> showDateFilterStatePicker({
  required DateFilterState selectedDateFilterState,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<DateFilterState>(
    builder: (_) => Picker<DateFilterState>(
      items: DateFilterState.all(selectedDateFilterState),
      selectedItem: selectedDateFilterState,
      title: (dateFilterState) => dateFilterState.name,
      compareWith: (dateFilterState) => dateFilterState,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<Metcon?> showMetconPicker({
  required Metcon? selectedMetcon,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Metcon>(
    builder: (_) => PickerWithSearch<Metcon>(
      selectedItem: selectedMetcon,
      getByName: (name) => MetconDataProvider().getByName(name),
      editRoute: Routes.metconEdit,
      compareWith: (m1, m2) => m1.id == m2?.id,
      title: (metcon) => metcon.name,
      subtitle: null,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<Movement?> showMovementPicker({
  required Movement? selectedMovement,
  bool cardioOnly = false,
  bool distanceOnly = false,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Movement>(
    builder: (_) => PickerWithSearch<Movement>(
      selectedItem: selectedMovement,
      getByName: (name) => MovementDataProvider()
          .getByName(name, cardioOnly: cardioOnly, distanceOnly: distanceOnly),
      editRoute: Routes.movementEdit,
      compareWith: (m1, m2) => m1.id == m2?.id,
      title: (movement) => movement.name,
      subtitle: (movement) => movement.dimension.name,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<MovementOrMetcon?> showMovementOrMetconPicker({
  required MovementOrMetcon? selectedMovementOrMetcon,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<MovementOrMetcon>(
    builder: (_) => PickerWithSearch<MovementOrMetcon>(
      selectedItem: selectedMovementOrMetcon,
      getByName: (name) async => ((await MovementDataProvider().getNonDeleted())
                  .map(MovementOrMetcon.movement)
                  .toList() +
              (await MetconDataProvider().getNonDeleted())
                  .map(MovementOrMetcon.metcon)
                  .toList())
          .fuzzySort(query: name, toString: (m) => m.name),
      editRoute: null,
      compareWith: (m1, m2) => m1 == m2,
      title: (movementOrMetcon) => movementOrMetcon.name,
      subtitle: (movementOrMetcon) => movementOrMetcon.movement?.dimension.name,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<Route?> showRoutePicker({
  required Route? selectedRoute,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Route>(
    builder: (_) => PickerWithSearch<Route>(
      selectedItem: selectedRoute,
      getByName: (name) => RouteDataProvider().getByName(name),
      editRoute: Routes.routeEdit,
      compareWith: (r1, r2) => r1.id == r2?.id,
      title: (route) => route.name,
      subtitle: null,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

Future<Weekday?> showWeekdayPicker({
  required Weekday? selectedWeekday,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Weekday>(
    builder: (_) => Picker<Weekday>(
      items: Weekday.values,
      selectedItem: selectedWeekday,
      title: (weekday) => weekday.name,
      compareWith: (weekday) => weekday.index,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}
