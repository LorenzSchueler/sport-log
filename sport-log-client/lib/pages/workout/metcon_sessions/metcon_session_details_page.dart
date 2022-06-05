import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_description_card.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_results_card.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

class MetconSessionDetailsPage extends StatefulWidget {
  const MetconSessionDetailsPage({
    Key? key,
    required this.metconSessionDescription,
  }) : super(key: key);

  final MetconSessionDescription metconSessionDescription;

  @override
  State<MetconSessionDetailsPage> createState() =>
      MetconSessionDetailsPageState();
}

class MetconSessionDetailsPageState extends State<MetconSessionDetailsPage> {
  final _dataProvider = MetconSessionDescriptionDataProvider();
  late MetconSessionDescription _metconSessionDescription;
  List<MetconSessionDescription> _metconSessionDescriptions = [];
  MetconRecords _metconRecords = {};

  @override
  void initState() {
    _metconSessionDescription = widget.metconSessionDescription.clone();
    _loadOtherSessions();
    super.initState();
  }

  Future<void> _loadOtherSessions() async {
    final metconSessionDescriptions =
        await _dataProvider.getByTimerangeAndMetcon(
      metcon: _metconSessionDescription.metconDescription.metcon,
    );
    final records = await _dataProvider.getMetconRecords();
    setState(() {
      _metconSessionDescriptions = metconSessionDescriptions;
      _metconRecords = records;
    });
  }

  Future<void> _deleteMetconSession() async {
    await _dataProvider.deleteSingle(widget.metconSessionDescription);
    if (mounted) {
      Navigator.pop(context);
    }
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
              if (returnObj is ReturnObject<MetconSessionDescription> &&
                  mounted) {
                if (returnObj.action == ReturnAction.deleted) {
                  Navigator.pop(context);
                } else {
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
          MetconDescriptionCard(
            metconDescription: _metconSessionDescription.metconDescription,
          ),
          Defaults.sizedBox.vertical.normal,
          MetconSessionResultsCard(
            metconSessionDescription: _metconSessionDescription,
            metconSessionDescriptions: _metconSessionDescriptions,
            metconRecords: _metconRecords,
          ),
        ],
      ),
    );
  }
}
