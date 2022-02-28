import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';

class MetconSessionDetailsPage extends StatefulWidget {
  final MetconSessionDescription metconSessionDescription;

  const MetconSessionDetailsPage({
    Key? key,
    required this.metconSessionDescription,
  }) : super(key: key);

  @override
  State<MetconSessionDetailsPage> createState() =>
      MetconSessionDetailsPageState();
}

class MetconSessionDetailsPageState extends State<MetconSessionDetailsPage> {
  final _logger = Logger('MetconSessionDetailsPage');
  final _dataProvider = MetconSessionDescriptionDataProvider.instance;

  Future<void> _deleteMetconSession() async {
    await _dataProvider.deleteSingle(widget.metconSessionDescription);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    MetconSessionDescription metconSessionDescription =
        widget.metconSessionDescription;

    return Scaffold(
      appBar: AppBar(
        title: Text(metconSessionDescription.metconDescription.name),
        actions: [
          IconButton(
            onPressed: _deleteMetconSession,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: () async {
              final returnObj = await Navigator.pushNamed(
                context,
                Routes.metcon.sessionEdit,
                arguments: metconSessionDescription,
              );
              if (returnObj is ReturnObject<MetconSessionDescription>) {
                if (returnObj.action == ReturnAction.deleted) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    metconSessionDescription = returnObj.payload;
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
            child: Text(metconSessionDescription.typeLengthDescription),
          ),
          TextTile(
            caption: "Movements",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var metconMovementDescription
                    in metconSessionDescription.metconDescription.moves)
                  Text(metconMovementDescription.movementText),
              ],
            ),
          ),
          if (metconSessionDescription.metconDescription.metcon.description !=
              null)
            TextTile(
              caption: "Description",
              child: Text(
                metconSessionDescription.metconDescription.metcon.description!,
              ),
            ),
          Defaults.sizedBox.vertical.big,
          const Text(
            "Results",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          TextTile(
            caption: "Score",
            child: Text(
              "${metconSessionDescription.shortResultDescription} (${metconSessionDescription.metconSession.datetime.formatDate})",
            ),
          ),
          const TextTile(
            caption: "Best Score",
            child: Text("<my best score> <date>"),
          ),
          if (metconSessionDescription.metconSession.comments != null)
            TextTile(
              caption: "Comments",
              child: Text(metconSessionDescription.metconSession.comments!),
            ),
        ],
      ),
    );
  }
}
