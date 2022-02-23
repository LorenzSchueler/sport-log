import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/extensions/list_extension.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/approve_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({Key? key}) : super(key: key);

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _dataProvider = MovementDataProvider.instance;
  List<MovementDescription> _movementDescriptions = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.getMovementDescriptions().then((mds) {
      setState(() {
        _movementDescriptions = mds;
      });
    });
  }

  void _handlePageReturn(dynamic object) {
    if (object is ReturnObject<MovementDescription>) {
      switch (object.action) {
        case ReturnAction.created:
          setState(() {
            _movementDescriptions.add(object.payload);
            _movementDescriptions.sortBy((m) => m.movement.name.toUpperCase());
            // TODO: "hide" server defined movements with same name/dimension
          });
          break;
        case ReturnAction.updated:
          setState(() {
            _movementDescriptions.update(object.payload,
                by: (o) => o.movement.id);
            _movementDescriptions.sortBy((m) => m.movement.name.toUpperCase());
            // TODO: "hide" server defined movements with same name/dimension
          });
          break;
        case ReturnAction.deleted:
          setState(() => _movementDescriptions.delete(object.payload,
              by: (m) => m.movement.id));
        // TODO: "unhide" server defined movements with same name/dimension
      }
    }
  }

  Future<void> _pullFromServer() async {
    await _dataProvider.pullFromServer().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
    final mds = await _dataProvider.getMovementDescriptions();
    setState(() {
      _movementDescriptions = mds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movements"),
      ),
      drawer: MainDrawer(selectedRoute: Routes.movement.overview),
      body: RefreshIndicator(
        onRefresh: _pullFromServer,
        child: _body(context),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            final returnObj =
                await Navigator.pushNamed(context, Routes.movement.edit);
            _handlePageReturn(returnObj);
          }),
    );
  }

  Widget _body(BuildContext context) {
    if (_movementDescriptions.isEmpty) {
      return const Center(child: Text("No movements there."));
    }
    return ImplicitlyAnimatedList(
      items: _movementDescriptions,
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
      child: ExpansionTileCard(
          leading: CircleAvatar(child: Text(movement.name[0])),
          title: Text(movement.name),
          subtitle: Text(movement.dimension.displayName),
          children: [
            if (movement.description != null) const Divider(),
            if (movement.description != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(movement.description!),
              ),
            if (movement.userId != null) const Divider(),
            if (movement.userId != null)
              ButtonBar(
                alignment: MainAxisAlignment.spaceAround,
                children: [
                  if (!md.hasReference)
                    IconButton(
                      onPressed: () {
                        assert(movement.userId != null && !md.hasReference);
                        _dataProvider.deleteSingle(movement);
                        setState(() => _movementDescriptions.delete(md,
                            by: (m) => m.movement.id));
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  IconButton(
                    onPressed: () async {
                      assert(movement.userId != null);
                      if (md.hasReference) {
                        final bool? approved = await showApproveDialog(
                            context,
                            'Warning',
                            'Changes will be reflected in existing workouts.');
                        if (approved == null || !approved) return;
                      }
                      final returnObj = await Navigator.pushNamed(
                        context,
                        Routes.movement.edit,
                        arguments: md.copy(),
                      );
                      _handlePageReturn(returnObj);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
          ]),
    );
  }
}
