import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

Future<Movement?> showMovementPicker({
  required BuildContext context,
  Movement? selectedMovement,
  bool dismissable = true,
  bool cardioOnly = false,
  bool distanceOnly = false,
}) async {
  return showDialog<Movement>(
    builder: (_) => MovementPickerDialog(
      selectedMovement: selectedMovement,
      cardioOnly: cardioOnly,
      distanceOnly: distanceOnly,
    ),
    barrierDismissible: dismissable,
    context: context,
  );
}

class MovementPickerDialog extends StatefulWidget {
  const MovementPickerDialog({
    Key? key,
    required this.selectedMovement,
    required this.cardioOnly,
    required this.distanceOnly,
  }) : super(key: key);

  final Movement? selectedMovement;
  final bool cardioOnly;
  final bool distanceOnly;

  @override
  State<MovementPickerDialog> createState() => _MovementPickerDialogState();
}

class _MovementPickerDialogState extends State<MovementPickerDialog> {
  final _dataProvider = MovementDataProvider();

  List<Movement> _movements = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _update('');
  }

  Future<void> _update(String newSearch) async {
    final movements = await _dataProvider.getByName(
      newSearch.trim(),
      cardioOnly: widget.cardioOnly,
      distanceOnly: widget.distanceOnly,
    );
    if (widget.selectedMovement != null) {
      final index = movements
          .indexWhere((movement) => movement.id == widget.selectedMovement!.id);
      if (index >= 0) {
        movements.insert(0, movements.removeAt(index));
      }
    }
    setState(() {
      _movements = movements;
      _search = newSearch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _searchBar,
          const Divider(height: 1, thickness: 2),
          Expanded(child: _movementList),
        ],
      ),
    );
  }

  Widget get _searchBar {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: TextFormField(
        initialValue: _search,
        onChanged: _update,
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(AppIcons.search),
          border: InputBorder.none,
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.movement.edit,
                    arguments: _search,
                  ),
                  icon: const Icon(AppIcons.add),
                )
              : null,
        ),
      ),
    );
  }

  Widget get _movementList {
    if (_movements.isEmpty) {
      return const Center(child: Text('No movements here.'));
    }

    return Scrollbar(
      child: ListView.separated(
        itemBuilder: _movementBuilder,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _movements.length,
      ),
    );
  }

  Widget _movementBuilder(BuildContext context, int index) {
    final movement = _movements[index];
    final selected = movement.id == widget.selectedMovement?.id;

    return ListTile(
      title: Text(movement.name),
      subtitle: Text(movement.dimension.displayName),
      onTap: () {
        Navigator.pop(context, movement);
      },
      selected: selected,
      trailing: selected ? const Icon(AppIcons.check) : null,
    );
  }
}
