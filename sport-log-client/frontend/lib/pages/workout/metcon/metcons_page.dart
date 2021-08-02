
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/models/metcon.dart';
import 'package:sport_log/pages/workout/metcon/metcons_cubit.dart';

import 'metcon_request_bloc.dart';

class MetconsPage extends StatelessWidget {
  const MetconsPage({Key? key}) : super(key: key);

  static const _deleteChoice = 1;
  static const _editChoice = 2;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MetconRequestBloc, MetconRequestState>(
      bloc: MetconRequestBloc.fromContext(context)
        ..add(const MetconRequestGetAll()),
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
                return ListView.builder(
                  itemCount: metcons.length,
                  itemBuilder: (context, index) {
                    final metcon = metcons[index];
                    return _metconToWidget(context, metcon);
                  },
                );
              }
            }
          );
        }
      },
    );
  }

  Widget _metconToWidget(BuildContext context, Metcon metcon) {
    return Card(
      child: ListTile(
        title: Text(metcon.name),
        trailing: PopupMenuButton(
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(
                value: _deleteChoice,
                child: Text("Edit"),
              ),
              const PopupMenuItem(
                value: _editChoice,
                child: Text("Delete"),
              ),
            ];
          },
          onSelected: (choice) {
            switch (choice) {
              case _deleteChoice:
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "This will get you to the edit metcon page.")
                    )
                );
                break;
              case _editChoice:
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("This will delete the metcon.")
                    )
                );
                break;
            }
          },
        ),
      ),
    );
  }
}