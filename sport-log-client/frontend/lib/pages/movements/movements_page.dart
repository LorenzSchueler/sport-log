
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/movement/ui_movement.dart';
import 'package:sport_log/pages/movements/movements_cubit.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import 'movement_request_bloc.dart';

class MovementsPage extends StatelessWidget {
  const MovementsPage({Key? key}) : super(key: key);

  static const _deleteChoice = 1;
  static const _editChoice = 2;

  int _compareFunction(Movement m1, Movement m2) {
    if (m1.userId != null) {
      if (m2.userId != null) {
        return m1.name.compareTo(m2.name);
      } else {
        return -1;
      }
    } else {
      if (m2.userId != null) {
        return 1;
      } else {
        return m1.name.compareTo(m2.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movements"),),
      drawer: const MainDrawer(selectedRoute: Routes.movements),
      body: _body(context),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(Routes.editMovement);
        }
      ),
    );
  }

  Widget _body(BuildContext context) {
    final requestBloc = MovementRequestBloc.fromContext(context);
    if (context.read<MovementsCubit>().state is MovementsInitial) {
      requestBloc.add(MovementRequestGetAll());
    }
    return BlocConsumer<MovementRequestBloc, MovementRequestState>(
      bloc: requestBloc,
      listener: (context, state) {
        if (state is MovementRequestFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.reason.toErrorMessage()))
          );
        }
      },
      builder: (context, state) {
        if (state is MovementRequestPending) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return BlocBuilder<MovementsCubit, MovementsState>(
            builder: (context, state) {
              if (state is MovementsInitial) {
                return const Center(
                  child: Text("Waiting for movements to be fetched."),
                );
              } else {
                assert(state is MovementsLoaded);
                final movements = (state as MovementsLoaded).movementsList;
                movements.sort(_compareFunction);
                if (movements.isEmpty) {
                  return const Center(child: Text("No movements there."));
                }
                return ImplicitlyAnimatedList(
                  items: movements,
                  itemBuilder: _movementToWidget,
                  areItemsTheSame: (Movement m1, Movement m2) =>
                    m1.id == m2.id,
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _movementToWidget(
      BuildContext context, animation, Movement movement, int index
  ) {
    final requestBloc = MovementRequestBloc.fromContext(context);
    return SizeFadeTransition(
      key: ValueKey(movement.id),
      animation: animation,
      child: BlocConsumer<MovementRequestBloc, MovementRequestState>(
        bloc: requestBloc,
        listener: (context, state) {
          if (state is MovementRequestFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.reason.toErrorMessage()))
            );
          }
        },
        builder: (context, state) {
          return Card(
            child: ListTile(
              title: Text(movement.name),
              trailing: (movement.userId == null) ? null : PopupMenuButton(
                enabled: state is! MovementRequestPending,
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: _editChoice,
                      child: Text("Edit"),
                    ),
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
                      requestBloc.add(MovementRequestDelete(movement.id));
                      break;
                    case _editChoice:
                      Navigator.of(context).pushNamed(
                        Routes.editMovement,
                        arguments: UiMovement.fromMovement(movement),
                      );
                      break;
                  }
                },
              ),
            ),
          );
        }
      ),
    );
  }
}