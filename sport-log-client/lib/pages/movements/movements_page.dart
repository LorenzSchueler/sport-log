import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/state/local_state.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({Key? key}) : super(key: key);

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  static const _deleteChoice = 1;
  static const _editChoice = 2;

  final _dataProvider = MovementDataProvider();
  LocalState<MovementDescription> _state = LocalState.empty();

  @override
  void initState() {
    super.initState();
    _dataProvider.getNonDeletedFull().then((mds) {
      setState(() {
        _state = LocalState.fromList(mds);
      });
    });
  }

  void handlePageReturn(dynamic object) {
    if (object is ReturnObject<MovementDescription>) {
      switch (object.action) {
        case ReturnAction.created:
          setState(() => _state.create(object.object));
          break;
        case ReturnAction.updated:
          setState(() => _state.update(object.object));
          break;
        case ReturnAction.deleted:
          setState(() => _state.delete(object.object.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movements"),
      ),
      drawer: const MainDrawer(selectedRoute: Routes.movements),
      body: _body(context),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context)
                .pushNamed(Routes.editMovement)
                .then(handlePageReturn);
          }),
    );
  }

  Widget _body(BuildContext context) {
    if (_state.isEmpty) {
      return const Center(child: Text("No movements there."));
    }
    return ImplicitlyAnimatedList(
      items: _state.sortedBy(_compareFunction),
      itemBuilder: _movementToWidget,
      areItemsTheSame: MovementDescription.areTheSame,
    );
  }

  Widget _movementToWidget(
    BuildContext context,
    Animation<double> animation,
    MovementDescription md,
    int index,
  ) {
    final movement = md.movement;
    return SizeFadeTransition(
      key: ValueKey(movement.id),
      animation: animation,
      child: Card(
        child: ListTile(
          title: Text(movement.name),
          trailing: (movement.userId == null)
              ? null
              : PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: _editChoice,
                        child: Text("Edit"),
                      ),
                      if (!md.hasReference)
                        const PopupMenuItem(
                          value: _deleteChoice,
                          child: Text("Delete"),
                        )
                    ];
                  },
                  onSelected: (choice) {
                    assert(movement.userId != null);
                    if (movement.userId == null) {
                      return;
                    }
                    switch (choice) {
                      case _deleteChoice:
                        _dataProvider.deleteSingle(movement);
                        setState(() => _state.delete(md.id));
                        break;
                      case _editChoice:
                        Navigator.of(context)
                            .pushNamed(
                              Routes.editMovement,
                              arguments: md,
                            )
                            .then(handlePageReturn);
                        break;
                    }
                  },
                ),
        ),
      ),
    );
  }

  int _compareFunction(MovementDescription m1, MovementDescription m2) {
    if (m1.movement.userId != null) {
      if (m2.movement.userId != null) {
        return m1.movement.name.compareTo(m2.movement.name);
      } else {
        return -1;
      }
    } else {
      if (m2.movement.userId != null) {
        return 1;
      } else {
        return m1.movement.name.compareTo(m2.movement.name);
      }
    }
  }
}
