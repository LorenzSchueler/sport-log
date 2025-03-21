import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_description_card.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class MetconDetailsPage extends StatefulWidget {
  const MetconDetailsPage({required this.metconDescription, super.key});

  final MetconDescription metconDescription;

  @override
  State<MetconDetailsPage> createState() => _MetconDetailsPageState();
}

class _MetconDetailsPageState extends State<MetconDetailsPage> {
  final _dataProvider = MetconDescriptionDataProvider();
  late MetconDescription _metconDescription = widget.metconDescription.clone();

  Future<void> _deleteMetcon() async {
    final delete = await showDeleteWarningDialog(context, "Metcon");
    if (!delete) {
      return;
    }
    assert(!_metconDescription.metcon.isDefaultMetcon);
    assert(!_metconDescription.hasReference);
    final result = await _dataProvider.deleteSingle(_metconDescription);
    if (mounted) {
      if (result.isOk) {
        Navigator.pop(context);
      } else {
        await showMessageDialog(
          context: context,
          title: "Deleting Metcon Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _pushEditPage() async {
    final returnObj = await Navigator.pushNamed(
      context,
      Routes.metconEdit,
      arguments: _metconDescription,
    );
    if (returnObj is ReturnObject<MetconDescription> && mounted) {
      if (returnObj.action == ReturnAction.deleted) {
        Navigator.pop(context);
      } else {
        setState(() {
          _metconDescription = returnObj.payload;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_metconDescription.metcon.name),
        actions: [
          IconButton(
            onPressed:
                () => Navigator.of(context).pushNamed(
                  Routes.metconSessionEdit,
                  arguments: _metconDescription,
                ),
            icon: const Icon(AppIcons.add),
          ),
          if (!_metconDescription.hasReference &&
              !_metconDescription.metcon.isDefaultMetcon)
            IconButton(
              onPressed: _deleteMetcon,
              icon: const Icon(AppIcons.delete),
            ),
          if (!_metconDescription.metcon.isDefaultMetcon)
            IconButton(
              onPressed: _pushEditPage,
              icon: const Icon(AppIcons.edit),
            ),
        ],
      ),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: MetconDescriptionCard(metconDescription: _metconDescription),
      ),
    );
  }
}
