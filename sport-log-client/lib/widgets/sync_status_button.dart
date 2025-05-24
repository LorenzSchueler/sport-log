import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/models/entity_interfaces.dart';

class SyncStatusButton<D extends EntityDataProvider, E extends AtomicEntity>
    extends StatefulWidget {
  const SyncStatusButton({
    required this.entity,
    required this.dataProvider,
    super.key,
  });

  final E entity;
  final D dataProvider;

  @override
  State<SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends State<SyncStatusButton> {
  SyncStatus? _syncStatus;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      final syncStatus = await widget.dataProvider.getSyncStatus(widget.entity);
      if (mounted) {
        setState(() => _syncStatus = syncStatus);
      }
    });
    super.initState();
  }

  Future<void> setSyncStatus(SyncStatus syncStatus) async {
    await widget.dataProvider.setSyncStatus(widget.entity, syncStatus);
    final newSyncStatus = await widget.dataProvider.getSyncStatus(
      widget.entity,
    );
    if (mounted) {
      setState(() => _syncStatus = newSyncStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _syncStatus != null
        ? SegmentedButton(
            segments: SyncStatus.values
                .map(
                  (status) =>
                      ButtonSegment(value: status, label: Text(status.name)),
                )
                .toList(),
            selected: {_syncStatus},
            showSelectedIcon: false,
            onSelectionChanged: (selected) => setSyncStatus(selected.first!),
          )
        : const Text("???");
  }
}
