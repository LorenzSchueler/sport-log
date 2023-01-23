import 'dart:async';

import 'package:flutter/material.dart' hide Route, Action;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/models/action/action.dart';
import 'package:sport_log/models/action/weekday.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
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

class PickerWithSearch<T extends HasId> extends StatefulWidget {
  const PickerWithSearch({
    required this.selectedItem,
    required this.getByName,
    required this.editRoute,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final T? selectedItem;
  final Future<List<T>> Function(String) getByName;
  final String editRoute;
  final String Function(T) title;
  final String Function(T)? subtitle;

  @override
  State<PickerWithSearch> createState() => _PickerWithSearchState<T>();
}

class _PickerWithSearchState<T extends HasId>
    extends State<PickerWithSearch<T>> {
  late final StreamSubscription<bool> _keyboardSubscription =
      KeyboardVisibilityController().onChange.listen((isVisible) {
    if (!isVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  });

  List<T> _items = [];
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

  Future<void> _update(String search) async {
    final items = await widget.getByName(search.trim());
    if (widget.selectedItem != null) {
      final index =
          items.indexWhere((item) => item.id == widget.selectedItem?.id);
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
          )
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
                        widget.editRoute,
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

    return ListTile(
      title: Text(widget.title(item)),
      subtitle:
          widget.subtitle != null ? Text(widget.subtitle!.call(item)) : null,
      selected: item.id == widget.selectedItem?.id,
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
  return showDialog<Metcon>(
    builder: (_) => PickerWithSearch<Metcon>(
      selectedItem: selectedMetcon,
      getByName: (name) => MetconDataProvider().getByName(name),
      editRoute: Routes.metconEdit,
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
  return showDialog<Movement>(
    builder: (_) => PickerWithSearch<Movement>(
      selectedItem: selectedMovement,
      getByName: (name) => MovementDataProvider()
          .getByName(name, cardioOnly: cardioOnly, distanceOnly: distanceOnly),
      editRoute: Routes.movementEdit,
      title: (movement) => movement.name,
      subtitle: (movement) => movement.dimension.name,
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
  return showDialog<Route>(
    builder: (_) => PickerWithSearch<Route>(
      selectedItem: selectedRoute,
      getByName: (name) => RouteDataProvider().getByName(name),
      editRoute: Routes.routeEdit,
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
