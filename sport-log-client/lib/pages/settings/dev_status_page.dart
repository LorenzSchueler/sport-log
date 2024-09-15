import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/platform_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/wod_data_provider.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/settings.dart';

class DevStatusPage extends StatefulWidget {
  const DevStatusPage({super.key});

  @override
  State<DevStatusPage> createState() => _DevStatusPageState();
}

class _DevStatusPageState extends State<DevStatusPage> {
  Map<SyncStatus, int>? diaryCounts;
  Map<SyncStatus, int>? wodCounts;
  Map<SyncStatus, int>? movementCounts;
  Map<SyncStatus, int>? strengthSessionCounts;
  Map<SyncStatus, int>? strengthSetCounts;
  Map<SyncStatus, int>? metconCounts;
  Map<SyncStatus, int>? metconSessionCounts;
  Map<SyncStatus, int>? metconMovementCounts;
  Map<SyncStatus, int>? cardioSessionCounts;
  Map<SyncStatus, int>? routeCounts;
  Map<SyncStatus, int>? platformCounts;
  Map<SyncStatus, int>? platformCredentialCounts;
  Map<SyncStatus, int>? actionProviderCounts;
  Map<SyncStatus, int>? actionCounts;
  Map<SyncStatus, int>? actionRuleCounts;
  Map<SyncStatus, int>? actionEventCounts;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      diaryCounts = await DiaryDataProvider().getCountBySyncStatus();
      wodCounts = await WodDataProvider().getCountBySyncStatus();
      movementCounts = await MovementDataProvider().getCountBySyncStatus();
      strengthSessionCounts =
          await StrengthSessionDataProvider().getCountBySyncStatus();
      strengthSetCounts =
          await StrengthSetDataProvider().getCountBySyncStatus();
      metconCounts = await MetconDataProvider().getCountBySyncStatus();
      metconSessionCounts =
          await MetconSessionDataProvider().getCountBySyncStatus();
      metconMovementCounts =
          await MetconMovementDataProvider().getCountBySyncStatus();
      cardioSessionCounts =
          await CardioSessionDataProvider().getCountBySyncStatus();
      routeCounts = await RouteDataProvider().getCountBySyncStatus();
      platformCounts = await PlatformDataProvider().getCountBySyncStatus();
      platformCredentialCounts =
          await PlatformCredentialDataProvider().getCountBySyncStatus();
      actionProviderCounts =
          await ActionProviderDataProvider().getCountBySyncStatus();
      actionCounts = await ActionDataProvider().getCountBySyncStatus();
      actionRuleCounts = await ActionRuleDataProvider().getCountBySyncStatus();
      actionEventCounts =
          await ActionEventDataProvider().getCountBySyncStatus();
      if (mounted) {
        setState(() {});
      }
    });
  }

  TableRow countsRow(
    String tableName,
    Int64 epoch,
    Map<SyncStatus, int>? counts,
  ) {
    return row(
      tableName,
      "$epoch",
      "${counts?[SyncStatus.synchronized]}",
      "${counts?[SyncStatus.created]}",
      "${counts?[SyncStatus.updated]}",
    );
  }

  TableRow row(
    String value1,
    String value2,
    String value3,
    String value4,
    String value5,
  ) {
    return TableRow(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(value1),
        ),
        Container(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(value2),
        ),
        Container(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(value3),
        ),
        Container(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(value4),
        ),
        Container(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(value5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final epochMap = Settings.instance.epochMap;
    return Scaffold(
      appBar: AppBar(title: const Text("Dev Status")),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: epochMap == null
            ? const Text("no account")
            : Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                columnWidths: const {
                  1: FlexColumnWidth(),
                  3: FlexColumnWidth(),
                  5: FlexColumnWidth(),
                  7: FlexColumnWidth(),
                },
                children: [
                  row("Table", "Epoch", "Synchronized", "Created", "Updated"),
                  row("user", "${epochMap.user}", "-", "-", "-"),
                  countsRow("diary", epochMap.diary, diaryCounts),
                  countsRow("wod", epochMap.wod, wodCounts),
                  countsRow("movement", epochMap.movement, movementCounts),
                  countsRow(
                    "strength session",
                    epochMap.strengthSession,
                    strengthSessionCounts,
                  ),
                  countsRow(
                    "strength set",
                    epochMap.strengthSet,
                    strengthSetCounts,
                  ),
                  countsRow("metcon", epochMap.metcon, metconCounts),
                  countsRow(
                    "metcon session",
                    epochMap.metconSession,
                    metconSessionCounts,
                  ),
                  countsRow(
                    "metcon movement",
                    epochMap.metconMovement,
                    metconMovementCounts,
                  ),
                  countsRow(
                    "cardio session",
                    epochMap.cardioSession,
                    cardioSessionCounts,
                  ),
                  countsRow("route", epochMap.route, routeCounts),
                  countsRow("platform", epochMap.platform, platformCounts),
                  countsRow(
                    "platform credentials",
                    epochMap.platformCredential,
                    platformCredentialCounts,
                  ),
                  countsRow(
                    "action provider",
                    epochMap.actionProvider,
                    actionProviderCounts,
                  ),
                  countsRow("action", epochMap.action, actionCounts),
                  countsRow(
                    "action rule",
                    epochMap.actionRule,
                    actionRuleCounts,
                  ),
                  countsRow(
                    "action event",
                    epochMap.actionEvent,
                    actionEventCounts,
                  ),
                ],
              ),
      ),
    );
  }
}
