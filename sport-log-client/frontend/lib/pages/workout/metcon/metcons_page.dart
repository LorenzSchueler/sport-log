
import 'package:flutter/material.dart';
import 'package:sport_log/models/metcon.dart';

class MetconsPage extends StatelessWidget {
  const MetconsPage({
    Key? key,
    required this.metcons,
  }) : super(key: key);

  final List<Metcon> metcons;

  static const _deleteChoice = 1;
  static const _editChoice = 2;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: metcons.length,
      itemBuilder: (context, index) {
        final metcon = metcons[index];
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
                        content: Text("This will get you to the edit metcon page.")
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
      },
    );
  }
}