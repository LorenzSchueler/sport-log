import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/extensions/list_extension.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metcons'),
      ),
      body: _content,
      drawer: MainDrawer(selectedRoute: Routes.metcon.overview),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            final returnObject =
                await Navigator.of(context).pushNamed(Routes.metcon.edit);
            if (returnObject is! ReturnObject<MetconDescription>) {
              return;
            }
            switch (returnObject.action) {
              case ReturnAction.updated:
                setState(() {
                  _metconDescriptions.update(returnObject.payload,
                      by: (md) => md.metcon.id);
                  _metconDescriptions.sortBy(
                      (md) => (md.metcon.name ?? 'Unnamed').toUpperCase());
                });
                break;
              case ReturnAction.created:
                setState(() {
                  _metconDescriptions.add(returnObject.payload);
                  _metconDescriptions.sortBy(
                      (md) => (md.metcon.name ?? 'Unnamed').toUpperCase());
                });
                break;
              case ReturnAction.deleted:
                setState(() {
                  _metconDescriptions.delete(returnObject.payload,
                      by: (md) => md.metcon.id);
                });
                break;
            }
          }),
    );
  }

  Widget get _content {
    if (_metconDescriptions.isEmpty) {
      return const Center(child: Text('No metcons there.'));
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
          title: Text(md.metcon.name ?? 'Unnamed'),
          subtitle: _subtitle(md),
          trailing: PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: _editChoice,
                  child: Text('Edit'),
                ),
                if (!md.hasReference && md.metcon.userId != null)
                  const PopupMenuItem(
                    value: _deleteChoice,
                    child: Text('Delete'),
                  ),
              ];
            },
            onSelected: (choice) async {
              switch (choice) {
                case _deleteChoice:
                  assert(!md.hasReference && md.metcon.userId != null);
                  _dataProvider.deleteSingle(md).then((_) {
                    setState(() {
                      _metconDescriptions.removeWhere(
                          (m) => MetconDescription.areTheSame(m, md));
                    });
                  });
                  break;
                case _editChoice:
                  final dynamic updatedMd = await Navigator.of(context)
                      .pushNamed(Routes.metcon.edit, arguments: md)
                      .then((_) {
                    _update();
                  });
                  if (updatedMd is MetconDescription) {
                    setState(() {});
                  }
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _subtitle(MetconDescription md) {
    return Text(
      md.moves.map((mmd) => mmd.movement.name).join(' • '),
      overflow: TextOverflow.ellipsis,
    );
  }
}