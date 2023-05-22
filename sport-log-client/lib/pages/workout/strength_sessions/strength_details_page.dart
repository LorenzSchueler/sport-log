import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/models/strength/strength_records.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_record_card.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class StrengthSessionDetailsPage extends StatefulWidget {
  const StrengthSessionDetailsPage({
    required this.strengthSessionDescription,
    super.key,
  });

  final StrengthSessionDescription strengthSessionDescription;

  @override
  StrengthSessionDetailsPageState createState() =>
      StrengthSessionDetailsPageState();
}

class StrengthSessionDetailsPageState
    extends State<StrengthSessionDetailsPage> {
  final _dataProvider = StrengthSessionDescriptionDataProvider();
  late StrengthSessionDescription _strengthSessionDescription =
      widget.strengthSessionDescription.clone();
  StrengthRecords strengthRecords = {};

  @override
  void initState() {
    _loadRecords();
    super.initState();
  }

  Future<void> _loadRecords() async {
    final records = await _dataProvider.getStrengthRecords();
    if (mounted) {
      setState(() {
        strengthRecords = records;
      });
    }
  }

  Future<void> _deleteStrengthSession() async {
    final delete = await showDeleteWarningDialog(context, "Strength Session");
    if (!delete) {
      return;
    }
    await _dataProvider.deleteSingle(_strengthSessionDescription);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pushEditPage() async {
    final returnObj = await Navigator.pushNamed(
      context,
      Routes.strengthEdit,
      arguments: _strengthSessionDescription,
    );
    if (returnObj is ReturnObject<StrengthSessionDescription> && mounted) {
      if (returnObj.action == ReturnAction.deleted) {
        Navigator.pop(context);
      } else {
        setState(() {
          _strengthSessionDescription = returnObj.payload;
        });
        await _loadRecords();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_strengthSessionDescription.movement.name),
        actions: [
          IconButton(
            onPressed: _deleteStrengthSession,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _pushEditPage,
            icon: const Icon(AppIcons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: Defaults.edgeInsets.normal,
        children: [
          _StrengthStatsCard(
            strengthSessionDescription: _strengthSessionDescription,
            strengthRecords: strengthRecords,
          ),
          if (_strengthSessionDescription.session.comments != null) ...[
            Defaults.sizedBox.vertical.normal,
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: Defaults.edgeInsets.normal,
                child: EditTile(
                  leading: null,
                  caption: 'Comments',
                  child: Text(
                    _strengthSessionDescription.session.comments!,
                  ),
                ),
              ),
            ),
          ],
          Defaults.sizedBox.vertical.normal,
          _StrengthSetsCard(
            strengthSessionDescription: _strengthSessionDescription,
            strengthRecords: strengthRecords,
          ),
          Defaults.sizedBox.vertical.normal,
          StrengthRecordsCard(
            strengthRecords: strengthRecords,
            movement: _strengthSessionDescription.movement,
          ),
        ],
      ),
    );
  }
}

class _StrengthStatsCard extends StatelessWidget {
  const _StrengthStatsCard({
    required this.strengthSessionDescription,
    required this.strengthRecords,
  });

  final StrengthSessionDescription strengthSessionDescription;
  final StrengthRecords strengthRecords;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          children: [
            EditTile(
              leading: null,
              caption: "Date",
              child: Text(
                strengthSessionDescription.session.datetime.toHumanDateTime(),
              ),
            ),
            EditTile(
              leading: null,
              caption: "Sets",
              child: Text(
                '${strengthSessionDescription.sets.length} sets',
              ),
            ),
            if (strengthSessionDescription.session.interval != null)
              EditTile(
                leading: null,
                caption: "Interval",
                child: Text(
                  strengthSessionDescription.session.interval!.formatTimeShort,
                ),
              ),
            ..._bestValuesInfo(strengthSessionDescription),
          ],
        ),
      ),
    );
  }

  // ignore: long-method
  List<Widget> _bestValuesInfo(StrengthSessionDescription session) {
    final stats = session.stats;
    final maxEorm = stats.maxEorm;
    final maxWeight = stats.maxWeight;
    final sumVolume = stats.sumVolume;
    return switch (session.movement.dimension) {
      MovementDimension.reps => [
          if (maxEorm != null)
            EditTile(
              leading: null,
              caption: 'Max Eorm',
              child: Text(formatWeight(maxEorm)),
            ),
          if (sumVolume != null)
            EditTile(
              leading: null,
              caption: 'Volume',
              child: Text(formatWeight(sumVolume)),
            ),
          if (maxWeight != null)
            EditTile(
              leading: null,
              caption: 'Max Weight',
              child: Text(formatWeight(maxWeight)),
            ),
          EditTile(
            leading: null,
            caption: 'Avg Reps',
            child: Text(stats.avgCount.toStringAsFixed(1)),
          )
        ],
      MovementDimension.time => [
          EditTile(
            leading: null,
            caption: 'Best Time',
            child: Text(Duration(milliseconds: stats.minCount).formatMsMill),
          ),
        ],
      MovementDimension.distance => [
          EditTile(
            leading: null,
            caption: 'Best Distance',
            child: Text("${stats.maxCount} m"),
          ),
        ],
      MovementDimension.energy => [
          EditTile(
            leading: null,
            caption: 'Total Energy',
            child: Text('${stats.sumCount} cal'),
          ),
        ],
    };
  }
}

class _StrengthSetsCard extends StatelessWidget {
  const _StrengthSetsCard({
    required this.strengthSessionDescription,
    required this.strengthRecords,
  });

  final StrengthSessionDescription strengthSessionDescription;
  final StrengthRecords strengthRecords;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: strengthSessionDescription.sets.mapIndexed(
            (index, set) {
              final recordTypes = strengthRecords.getRecordTypes(
                set,
                strengthSessionDescription.movement,
              );
              return EditTile(
                leading: null,
                caption: "Set ${index + 1}",
                child: Row(
                  children: [
                    Text(
                      set.toDisplayName(
                        strengthSessionDescription.movement.dimension,
                        withEorm: true,
                      ),
                    ),
                    if (recordTypes.isNotEmpty) ...[
                      Defaults.sizedBox.horizontal.normal,
                      StrengthRecordMarkers(
                        strengthRecordTypes: recordTypes,
                      ),
                    ],
                  ],
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
