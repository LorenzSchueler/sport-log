
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/models/movement.dart';
import 'package:sport_log/repositories/movement_repository.dart';

class MovementPickerDialog extends StatefulWidget {
  const MovementPickerDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MovementPickerDialogState();
}

class _MovementPickerDialogState extends State<MovementPickerDialog> {

  String _searchTerm = "";
  List<Movement> _movements = [];

  @override
  void initState() {
    setState(() {
      _movements = context.read<MovementRepository>().getAllMovements();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 10
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            _searchTextField(),
            ..._results(context),
          ],
        ),
      ),
    );
  }

  Widget _searchTextField() {
    return TextField(
      onChanged: (text) {
        setState(() {
          _searchTerm = text;
          _movements = context.read<MovementRepository>().searchByName(text);
        });
      },
      decoration: const InputDecoration(
        labelText: "search",
        border: OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _results(BuildContext context) {
    return _movements.map((movement) => ListTile(
      title: Text(movement.name),
      subtitle: (movement.description != null)
          ? Text(movement.description!) : null,
      key: ValueKey(movement.id),
      onTap: () => Navigator.of(context).pop(movement.id),
    )).toList();
  }
}