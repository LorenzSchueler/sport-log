import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Action, Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/sort_extension.dart';
import 'package:sport_log/models/action/action.dart';
import 'package:sport_log/models/action/weekday.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/timeline_union.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

class Picker<T, C> extends StatelessWidget {
  const Picker({
    required this.items,
    required this.selectedItem,
    required this.title,
    required this.subtitle,
    required this.compareWith,
    super.key,
  });

  final List<T> items;
  final T? selectedItem;
  final String Function(T) title;
  final String Function(T)? subtitle;
  final C Function(T) compareWith;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(title(item)),
            subtitle: subtitle != null ? Text(subtitle!.call(item)) : null,
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

class PickerWithSearch<T, C> extends StatefulWidget {
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
  final C Function(T) compareWith;
  final String Function(T) title;
  final String? Function(T)? subtitle;

  @override
  State<PickerWithSearch<T, C>> createState() => _PickerWithSearchState<T, C>();
}

class _PickerWithSearchState<T, C> extends State<PickerWithSearch<T, C>> {
  List<T> _items = [];
  String _search = '';

  @override
  void initState() {
    _update('');
    super.initState();
  }

  Future<void> _update(String search) async {
    final items = await widget.getByName(search.trim());
    final selectedItem = widget.selectedItem;
    if (selectedItem != null) {
      final index = items.indexWhere(
        (item) => widget.compareWith(item) == widget.compareWith(selectedItem),
      );
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
    final selectedItem = widget.selectedItem;

    return ListTile(
      title: Text(widget.title(item)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      selected: selectedItem != null
          ? widget.compareWith(item) == widget.compareWith(selectedItem)
          : false,
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
    builder: (_) => Picker(
      items: actions,
      selectedItem: selectedAction,
      title: (action) => action.name,
      subtitle: null,
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
    builder: (_) => Picker(
      items: CardioType.values,
      selectedItem: selectedCardioType,
      title: (cardioType) => cardioType.name,
      subtitle: null,
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
    builder: (_) => Picker(
      items: DateFilterState.all(selectedDateFilterState),
      selectedItem: selectedDateFilterState,
      title: (dateFilterState) => dateFilterState.name,
      subtitle: null,
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
    builder: (_) => PickerWithSearch(
      selectedItem: selectedMetcon,
      getByName: (name) => MetconDataProvider().getByName(name),
      editRoute: Routes.metconEdit,
      compareWith: (metcon) => metcon.id,
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
    builder: (_) => PickerWithSearch(
      selectedItem: selectedMovement,
      getByName: (name) => MovementDataProvider()
          .getByName(name, cardioOnly: cardioOnly, distanceOnly: distanceOnly),
      editRoute: Routes.movementEdit,
      compareWith: (movement) => movement.id,
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
    builder: (_) => PickerWithSearch(
      selectedItem: selectedMovementOrMetcon,
      getByName: (name) async => ((await MovementDataProvider().getNonDeleted())
                  .map(MovementOrMetcon.movement)
                  .toList() +
              (await MetconDataProvider().getNonDeleted())
                  .map(MovementOrMetcon.metcon)
                  .toList())
          .fuzzySort(query: name, toString: (m) => m.name),
      editRoute: null,
      compareWith: (movementOrMetcon) => movementOrMetcon,
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
    builder: (_) => PickerWithSearch(
      selectedItem: selectedRoute,
      getByName: (name) => RouteDataProvider().getByName(name),
      editRoute: Routes.routeEdit,
      compareWith: (route) => route.id,
      title: (route) => route.name,
      subtitle: null,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

// ignore: long-parameter-list
Future<CardioSession?> showProvidedCardioSessionPicker({
  required CardioSession? selected,
  required Movement movement,
  required List<CardioSession> cardioSessions,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return context.mounted
      ? showDialog<CardioSession>(
          builder: (_) => Picker(
            selectedItem: selected,
            items: cardioSessions,
            compareWith: (cs) => cs.id,
            title: (_) => movement.name,
            subtitle: (cs) => cs.datetime.humanDateTime,
          ),
          barrierDismissible: dismissible,
          context: context,
        )
      : null;
}

Future<CardioSession?> showCardioSessionPicker({
  required CardioSession? selected,
  required Movement movement,
  required bool hasTrack,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final idDatetimes =
      await CardioSessionDataProvider().getIdDatetimeByMovementWithTrack(
    movement: movement,
    hasTrack: hasTrack,
  );
  if (!context.mounted) {
    return null;
  }
  final newSelected = await showDialog<(Int64, DateTime)>(
    builder: (_) => Picker(
      selectedItem: selected != null ? (selected.id, selected.datetime) : null,
      items: idDatetimes,
      compareWith: (idDatetime) => idDatetime.$1,
      title: (_) => movement.name,
      subtitle: (idDatetime) => idDatetime.$2.humanDateTime,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
  return newSelected != null
      ? CardioSessionDataProvider().getById(newSelected.$1)
      : null;
}

Future<Weekday?> showWeekdayPicker({
  required Weekday? selectedWeekday,
  bool dismissible = true,
  required BuildContext context,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Weekday>(
    builder: (_) => Picker(
      items: Weekday.values,
      selectedItem: selectedWeekday,
      title: (weekday) => weekday.name,
      compareWith: (weekday) => weekday.index,
      subtitle: null,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}
