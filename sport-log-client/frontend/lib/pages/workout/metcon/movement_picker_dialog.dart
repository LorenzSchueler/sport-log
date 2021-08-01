
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
              (context, index) => _movementToWidget(_movements[index]),
              childCount: _movements.length
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchTextField() {
    return TextField(
      onChanged: (text) {
        setState(() {
          _movements = context.read<MovementRepository>().searchByName(text);
        });
      },
      decoration: const InputDecoration(
        labelText: "Search",
        icon: Icon(Icons.search)
      ),
    );
  }

  Widget _movementToWidget(Movement m) {
    return ListTile(
      title: Text(m.name),
      subtitle: (m.description != null)
          ? Text(
        m.description!,
        overflow: TextOverflow.ellipsis,
      ) : null,
      onTap: () => Navigator.of(context).pop(m.id),
    );
  }
}