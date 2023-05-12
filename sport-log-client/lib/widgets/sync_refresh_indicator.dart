import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/widgets/snackbar.dart';

class SyncRefreshIndicator extends StatelessWidget {
  const SyncRefreshIndicator({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<Sync>(
      builder: (context, sync, _) {
        return RefreshIndicator(
          onRefresh: () => sync.sync(
            onNoInternet: () => showNoInternetToast(context),
          ),
          child: child,
        );
      },
    );
  }
}

class RefreshableNoEntriesText extends StatelessWidget {
  const RefreshableNoEntriesText({required this.text, super.key});

  final String text;
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(child: Text(text, textAlign: TextAlign.center)),
        ),
      ],
    );
  }
}
