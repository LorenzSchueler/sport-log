import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/platform_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/models/platform/platform_credential.dart';
import 'package:sport_log/models/platform/platform_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

class PlatformOverviewPage extends StatelessWidget {
  const PlatformOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<PlatformDescription, void,
              PlatformDescriptionDataProvider, void>>(
        create: (_) => OverviewDataProvider(
          dataProvider: PlatformDescriptionDataProvider(),
          entityAccessor: (dataProvider) =>
              (_, __, ___, ____) => dataProvider.getNonDeleted(),
          recordAccessor: (_) => () async {},
          loggerName: "PlatformOverviewPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(title: const Text("Server Actions")),
          body: SyncRefreshIndicator(
            child: dataProvider.entities.isEmpty
                ? const RefreshableNoEntriesText(
                    text: "Looks like there are no registered platforms 😔",
                  )
                : Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: ListView.separated(
                      itemBuilder: (_, index) => PlatformCard(
                        platformDescription: dataProvider.entities[index],
                      ),
                      separatorBuilder: (_, __) =>
                          Defaults.sizedBox.vertical.normal,
                      itemCount: dataProvider.entities.length,
                    ),
                  ),
          ),
          drawer: const MainDrawer(selectedRoute: Routes.platformOverview),
        ),
      ),
    );
  }
}

class PlatformCard extends StatelessWidget {
  const PlatformCard({required this.platformDescription, super.key});

  final PlatformDescription platformDescription;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  platformDescription.platform.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Defaults.sizedBox.horizontal.normal,
                Icon(
                  !platformDescription.platform.credential ||
                          platformDescription.platformCredential != null
                      ? AppIcons.check
                      : AppIcons.close,
                ),
                const Spacer(),
                if (platformDescription.platform.credential)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => showDialog<void>(
                      builder: (_) =>
                          PlatformCredentialDialog(platformDescription),
                      context: context,
                    ),
                    icon: const Icon(AppIcons.settings),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(),
            for (final actionProvider
                in platformDescription.actionProviders) ...[
              Defaults.sizedBox.vertical.small,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: !platformDescription.platform.credential ||
                        platformDescription.platformCredential != null
                    ? () => Navigator.of(context).pushNamed(
                          Routes.actionProviderOverview,
                          arguments: actionProvider,
                        )
                    : () => showMessageDialog(
                          context: context,
                          title: "No Credentials",
                          text:
                              "Credentials are needed before you can use the action provider.",
                        ),
                child: Text(actionProvider.name),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PlatformCredentialDialog extends StatefulWidget {
  const PlatformCredentialDialog(this.platformDescription, {super.key});
  final PlatformDescription platformDescription;
  bool get isNew => platformDescription.platformCredential == null;

  @override
  State<PlatformCredentialDialog> createState() =>
      _PlatformCredentialDialogState();
}

class _PlatformCredentialDialogState extends State<PlatformCredentialDialog> {
  late PlatformDescription platformDescription =
      widget.platformDescription.clone()
        ..platformCredential ??= PlatformCredential.defaultValue(
          widget.platformDescription.platform.id,
        );
  final _dataProvider = PlatformDescriptionDataProvider();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              onChanged: (username) => setState(() {
                platformDescription.platformCredential!.username = username;
              }),
              initialValue: platformDescription.platformCredential!.username,
              decoration: const InputDecoration(
                icon: Icon(AppIcons.account),
                labelText: "Username",
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
            ),
            ProviderConsumer(
              create: (_) => BoolToggle.on(),
              builder: (context, obscure, _) => TextFormField(
                onChanged: (password) => setState(() {
                  platformDescription.platformCredential!.password = password;
                }),
                initialValue: platformDescription.platformCredential!.password,
                decoration: InputDecoration(
                  icon: const Icon(AppIcons.key),
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: obscure.isOn
                        ? const Icon(AppIcons.visibility)
                        : const Icon(AppIcons.visibilityOff),
                    onPressed: obscure.toggle,
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.done,
                obscureText: obscure.isOn,
              ),
            ),
            Defaults.sizedBox.vertical.normal,
            Padding(
              // 24 icon + 15 padding
              padding: const EdgeInsets.only(left: 24 + 15),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _update,
                    child: Text(widget.isNew ? "Create" : "Edit"),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _delete,
                    child: Text(widget.isNew ? "Back" : "Delete"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(platformDescription)
        : await _dataProvider.updateSingle(platformDescription);
    if (mounted) {
      if (result.isFailure) {
        await showMessageDialog(
          context: context,
          title: "${widget.isNew ? 'Creating' : 'Updating'} Credentials Failed",
          text: result.failure.toString(),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _delete() async {
    final delete = await showDeleteWarningDialog(context, "Credentials");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result = await _dataProvider.deleteSingle(platformDescription);
      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(context);
        } else {
          await showMessageDialog(
            context: context,
            title: "Deleting Credentials Failed",
            text: result.failure.toString(),
          );
        }
      }
    } else if (mounted) {
      Navigator.pop(context);
    }
  }
}
