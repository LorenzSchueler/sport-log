import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';

class MetconDetailsPage extends StatefulWidget {
  final MetconDescription metconDescription;

  const MetconDetailsPage({
    Key? key,
    required this.metconDescription,
  }) : super(key: key);

  @override
  State<MetconDetailsPage> createState() => MetconDetailsPageState();
}

class MetconDetailsPageState extends State<MetconDetailsPage> {
  final _logger = Logger('MetconSessionDetailsPage');
  final _dataProvider = MetconDescriptionDataProvider.instance;
  late MetconDescription _metconDescription;

  @override
  void initState() {
    _metconDescription = widget.metconDescription;
    super.initState();
  }

  Future<void> _deleteMetcon() async {
    await _dataProvider.deleteSingle(widget.metconDescription);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_metconDescription.metcon.name),
        actions: [
          IconButton(
            onPressed: _deleteMetcon,
            icon: const Icon(AppIcons.delete),
          ),
          if (widget.metconDescription.metcon.userId != null)
            IconButton(
              onPressed: () async {
                final returnObj = await Navigator.pushNamed(
                  context,
                  Routes.metcon.edit,
                  arguments: _metconDescription,
                );
                if (returnObj is ReturnObject<MetconDescription>) {
                  if (returnObj.action == ReturnAction.deleted) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _metconDescription = returnObj.payload;
                    });
                  }
                }
              },
              icon: const Icon(AppIcons.edit),
            )
        ],
      ),
      body: ListView(
        padding: Defaults.edgeInsets.normal,
        children: [
          const Text(
            "Metcon",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          TextTile(
            caption: "Type",
            child: Text(_metconDescription.typeLengthDescription),
          ),
          TextTile(
            caption: "Movements",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var metconMovementDescription in _metconDescription.moves)
                  Text(metconMovementDescription.movementText),
              ],
            ),
          ),
          if (_metconDescription.metcon.description != null)
            TextTile(
              caption: "Description",
              child: Text(
                _metconDescription.metcon.description!,
              ),
            ),
        ],
      ),
    );
  }
}
