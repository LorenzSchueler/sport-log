import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';

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

  Future<void> _deleteMetcon() async {
    await _dataProvider.deleteSingle(widget.metconDescription);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    MetconDescription metconDescription = widget.metconDescription;

    return Scaffold(
      appBar: AppBar(
        title: Text(metconDescription.name),
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
                  arguments: metconDescription,
                );
                if (returnObj is ReturnObject<MetconDescription>) {
                  if (returnObj.action == ReturnAction.deleted) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      metconDescription = returnObj.payload;
                    });
                  }
                }
              },
              icon: const Icon(AppIcons.edit),
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const Text(
            "Metcon",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          TextTile(
            caption: "Type",
            child: Text(metconDescription.typeLengthDescription),
          ),
          TextTile(
            caption: "Movements",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var metconMovementDescription in metconDescription.moves)
                  Text(metconMovementDescription.movementText),
              ],
            ),
          ),
          if (metconDescription.metcon.description != null)
            TextTile(
              caption: "Description",
              child: Text(
                metconDescription.metcon.description!,
              ),
            ),
        ],
      ),
    );
  }
}
