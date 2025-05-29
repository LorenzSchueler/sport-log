import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_provider.dart';
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
  final epochMap = Settings.instance.epochMap;
  late final List<(String, EntityDataProvider?, Int64?)> allRaw = [
    ("User", null, epochMap?.user),
    ("Diary", DiaryDataProvider(), epochMap?.diary),
    ("Wod", WodDataProvider(), epochMap?.wod),
    ("Movement", MovementDataProvider(), epochMap?.movement),
    (
      "Strength Session",
      StrengthSessionDataProvider(),
      epochMap?.strengthSession,
    ),
    ("Strength Set", StrengthSetDataProvider(), epochMap?.strengthSet),
    ("Metcon", MetconDataProvider(), epochMap?.metcon),
    ("Metcon Session", MetconSessionDataProvider(), epochMap?.metconSession),
    ("Metcon Movement", MetconMovementDataProvider(), epochMap?.metconMovement),
    ("Cardio Session", CardioSessionDataProvider(), epochMap?.cardioSession),
    ("Route", RouteDataProvider(), epochMap?.route),
    ("Platform", PlatformDataProvider(), epochMap?.platform),
    (
      "Platform Credential",
      PlatformCredentialDataProvider(),
      epochMap?.platformCredential,
    ),
    ("Action Provider", ActionProviderDataProvider(), epochMap?.actionProvider),
    ("Action", ActionDataProvider(), epochMap?.action),
    ("Action Rule", ActionRuleDataProvider(), epochMap?.actionRule),
    ("Action Event", ActionEventDataProvider(), epochMap?.actionEvent),
  ];
  List<(String, Map<SyncStatus, int>?, Int64?)>? all;
  String? checksum;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      all = await Future.wait(
        allRaw.map((x) async {
          final y = await x.$2?.getCountBySyncStatus();
          return (x.$1, y, x.$3);
        }),
      );

      final output = AccumulatorSink<Digest>();
      final input = sha256.startChunkedConversion(output);
      for (final (_, syncStatusCounts, epoch) in all!) {
        input
          ..add([
            for (final syncStatus in SyncStatus.values)
              syncStatusCounts?[syncStatus] ?? 0,
          ])
          ..add(epoch?.toBytes() ?? [0]);
      }
      input.close();
      checksum = output.events.single.bytes
          .map((b) => b.toRadixString(16))
          .join();
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
      "${counts?[SyncStatus.synchronized] ?? 0}",
      "${counts?[SyncStatus.created] ?? 0}",
      "${counts?[SyncStatus.updated] ?? 0}",
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
        Align(alignment: Alignment.centerLeft, child: Text(value1)),
        Container(),
        Align(alignment: Alignment.centerRight, child: Text(value2)),
        Container(),
        Align(alignment: Alignment.centerRight, child: Text(value3)),
        Container(),
        Align(alignment: Alignment.centerRight, child: Text(value4)),
        Container(),
        Align(alignment: Alignment.centerRight, child: Text(value5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dev Status")),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: all == null
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
                  for (final (name, syncStatus, epoch) in all!)
                    countsRow(name, epoch ?? Int64(), syncStatus),
                  row("", "", "", "", ""),
                  row("Checksum", checksum?.substring(0, 8) ?? "", "", "", ""),
                ],
              ),
      ),
    );
  }
}
