import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

class MovementPickerDialog extends StatefulWidget {
  const MovementPickerDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MovementPickerDialogState();
}

class _MovementPickerDialogState extends State<MovementPickerDialog> {
  List<Movement> _movements = [];
  String _searchTerm = "";
  bool _anyFullMatches = false;

  bool get _canCreateNewMovement =>
      _searchTerm.isNotEmpty && _anyFullMatches == false;

  final _dataProvider = MovementDataProvider();

  @override
  void initState() {
    _dataProvider.getNonDeleted().then((ms) {
      setState(() {
        _movements = ms;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: if no movements found (without entering anything), create new
    return WideScreenFrame(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: _searchTextField(),
              floating: true,
              snap: true,
              pinned: false,
              automaticallyImplyLeading: false,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (_canCreateNewMovement) {
                    return index == 0
                        ? _newMovementButton(context)
                        : _movementToWidget(_movements[index - 1]);
                  } else {
                    return _movementToWidget(_movements[index]);
                  }
                },
                childCount: _canCreateNewMovement
                    ? _movements.length + 1
                    : _movements.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchTextField() {
    return TextFormField(
      initialValue: _searchTerm,
      onChanged: (text) async {
        final ms = await _dataProvider.searchByName(text);
        setState(() {
          _movements = ms;
          _searchTerm = text;
          final search = _searchTerm.toLowerCase();
          _anyFullMatches = _movements
              .any((movement) => movement.name.toLowerCase() == search);
        });
      },
      decoration:
          const InputDecoration(labelText: "Search", icon: Icon(Icons.search)),
    );
  }

  Widget _newMovementButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: Text("Create new movement '$_searchTerm'"),
      onTap: () async {
        dynamic movement = await Navigator.of(context).pushNamed(
          Routes.editMovement,
          arguments: _searchTerm,
        );
        if (movement is Movement) {
          Navigator.of(context).pop(movement);
        }
      },
    );
  }

  Widget _movementToWidget(Movement m) {
    return ListTile(
      title: Text(m.name),
      subtitle: Text(m.unit.toDimensionName()),
      onTap: () => Navigator.of(context).pop(m),
    );
  }
}
