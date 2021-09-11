import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/routes.dart';

class MetconsPage extends StatefulWidget {
  const MetconsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MetconsPageState();
}

class _MetconsPageState extends State<MetconsPage> {
  final _dataProvider = MetconDataProvider();
  List<MetconDescription> _metconDescriptions = [];

  static const _deleteChoice = 1;
  static const _editChoice = 2;

  @override
  void initState() {
    super.initState();
    _update();
  }

  void _update() async {
    final mds = await _dataProvider.getNonDeleted();
    setState(() {
      _metconDescriptions = mds;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_metconDescriptions.isEmpty) {
      return const Center(child: Text("No metcons there."));
    }
    return ImplicitlyAnimatedList(
      items: _metconDescriptions,
      itemBuilder: _metconToWidget,
      areItemsTheSame: MetconDescription.areTheSame,
    );
  }

  Widget _metconToWidget(BuildContext context, Animation<double> animation,
      MetconDescription md, int index) {
    return SizeFadeTransition(
      key: ValueKey(md.metcon.id),
      animation: animation,
      child: Card(
        child: ListTile(
          title: Text(md.metcon.name ?? "Unnamed"),
          subtitle: _subtitle(md.metcon),
          trailing: PopupMenuButton(
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
                  _dataProvider.deleteSingle(md).then((_) {
                    setState(() {
                      _metconDescriptions.removeWhere(
                          (m) => MetconDescription.areTheSame(m, md));
                    });
                  });
                  break;
                case _editChoice:
                  Navigator.of(context)
                      .pushNamed(Routes.editMetcon, arguments: md)
                      .then((_) {
                    _update();
                  });
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _subtitle(Metcon metcon) {
    return const Text(
      "subtitle",
      overflow: TextOverflow.ellipsis,
    );
  }
}
