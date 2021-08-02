
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/models/metcon.dart';
import 'package:sport_log/pages/workout/metcon/metcons_cubit.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import 'metcon_request_bloc.dart';

class MetconsPage extends StatefulWidget {
  const MetconsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MetconsPageState();
}

// FIXME: don't use StatefulWidget if not necessary
class _MetconsPageState extends State<MetconsPage> {

  static const _deleteChoice = 1;
  static const _editChoice = 2;

  @override
  Widget build(BuildContext context) {
    final requestBloc = MetconRequestBloc.fromContext(context);
    if (context.read<MetconsCubit>().state is MetconsInitial) {
      requestBloc.add(const MetconRequestGetAll());
    }
    return BlocConsumer<MetconRequestBloc, MetconRequestState>(
      bloc: requestBloc,
      listener: (context, state) {
        if (state is MetconRequestFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.reason.toErrorMessage()))
          );
        }
      },
      builder: (context, state) {
        if (state is MetconRequestPending) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return BlocBuilder<MetconsCubit, MetconsState>(
              builder: (context, state) {
                if (state is MetconsInitial) {
                  return const Center(
                      child: Text("Waiting for metcons to be fetched.")
                  );
                } else {
                  assert(state is MetconsLoaded);
                  final metcons = (state as MetconsLoaded).metconsList;
                  if (metcons.isEmpty) {
                    return const Center(child: Text("No metcons there."));
                  }
                  return ImplicitlyAnimatedList(
                    items: metcons,
                    itemBuilder: _metconToWidget,
                    areItemsTheSame: (Metcon m1, Metcon m2) => m1.id == m2.id,
                  );
                }
              }
          );
        }
      },
    );
  }

  Widget _metconToWidget(
    BuildContext context,
    animation,
    Metcon metcon,
    int index
  ) {
    final requestBloc = MetconRequestBloc.fromContext(context);
    return SizeFadeTransition(
      key: ValueKey(metcon.id),
      animation: animation,
      child: BlocConsumer<MetconRequestBloc, MetconRequestState>(
        bloc: requestBloc,
        listener: (context, state) {
          if (state is MetconRequestFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.reason.toErrorMessage()))
            );
          }
        },
        builder: (context, state) {
          return Card(
            child: ListTile(
              title: Text(metcon.name),
              trailing: PopupMenuButton(
                enabled: state is! MetconRequestPending,
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: _editChoice,
                      child: Text("Edit"),
                    ),
                    const PopupMenuItem(
                      value: _deleteChoice,
                      child: Text("Delete"),
                    ),
                  ];
                },
                onSelected: (choice) {
                  switch (choice) {
                    case _deleteChoice:
                      requestBloc.add(MetconRequestDelete(metcon.id));
                      break;
                    case _editChoice:
                      // TODO
                      break;
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}