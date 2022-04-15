import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';

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
  final _dataProvider = MetconSessionDescriptionDataProvider();
  late MetconSessionDescription _metconSessionDescription;
  List<MetconSessionDescription> _metconSessionDescriptions = [];

  @override
  void initState() {
    _metconSessionDescription = widget.metconSessionDescription;
    _loadOtherSessions();
    super.initState();
  }

  Future<void> _loadOtherSessions() async {
    final metconSessionDescriptions =
        await _dataProvider.getByTimerangeAndMetcon(
      metcon: _metconSessionDescription.metconDescription.metcon,
    );
    setState(() => _metconSessionDescriptions = metconSessionDescriptions);
  }

  Future<void> _deleteMetconSession() async {
    await _dataProvider.deleteSingle(widget.metconSessionDescription);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_metconSessionDescription.metconDescription.metcon.name),
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
                arguments: _metconSessionDescription,
              );
              if (returnObj is ReturnObject<MetconSessionDescription>) {
                if (returnObj.action == ReturnAction.deleted) {
                  Navigator.pop(context);
                } else if (mounted) {
                  setState(() {
                    _metconSessionDescription = returnObj.payload;
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
          Text(
            "Metcon",
            style: Theme.of(context).textTheme.headline5,
          ),
          TextTile(
            caption: "Type",
            child: Text(_metconSessionDescription.typeLengthDescription),
          ),
          TextTile(
            caption: "Movements",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var metconMovementDescription
                    in _metconSessionDescription.metconDescription.moves)
                  Text(metconMovementDescription.movementText),
              ],
            ),
          ),
          if (_metconSessionDescription.metconDescription.metcon.description !=
              null)
            TextTile(
              caption: "Description",
              child: Text(
                _metconSessionDescription.metconDescription.metcon.description!,
              ),
            ),
          Defaults.sizedBox.vertical.big,
          Text(
            "Results",
            style: Theme.of(context).textTheme.headline5,
          ),
          TextTile(
            caption: "Score",
            child: Text(
              "${_metconSessionDescription.shortResultDescription} (${_metconSessionDescription.metconSession.datetime.toHumanDate()})",
            ),
          ),
          TextTile(
            caption: "Previous Scores",
            child: Column(
              children: [
                for (final metconSessionDescription
                    in _metconSessionDescriptions)
                  Text(
                    "${metconSessionDescription.shortResultDescription} (${metconSessionDescription.metconSession.datetime.toHumanDate()})",
                  ),
              ],
            ),
          ),
          if (_metconSessionDescription.metconSession.comments != null)
            TextTile(
              caption: "Comments",
              child: Text(_metconSessionDescription.metconSession.comments!),
            ),
        ],
      ),
    );
  }
}
