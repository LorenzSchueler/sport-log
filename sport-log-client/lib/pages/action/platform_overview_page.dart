import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/platform/platform_credential.dart';
import 'package:sport_log/models/platform/platform_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class PlatformOverviewPage extends StatefulWidget {
  const PlatformOverviewPage({Key? key}) : super(key: key);

  @override
  State<PlatformOverviewPage> createState() => _PlatformOverviewPageState();
}

class _PlatformOverviewPageState extends State<PlatformOverviewPage> {
  final _logger = Logger('PlatformOverviewPage');
  List<PlatformDescription> _platformDescriptions = [];
  final _dataProvider = PlatformDescriptionDataProvider();

  @override
  void initState() {
    super.initState();
    _dataProvider
      ..addListener(_update)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _update();
  }

  @override
  void dispose() {
    _dataProvider
      ..removeListener(_update)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d('Updating platform page');
    final platformDescriptions = await _dataProvider.getNonDeleted();
    setState(() => _platformDescriptions = platformDescriptions);
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Server Actions"),
        ),
        body: RefreshIndicator(
          onRefresh: _dataProvider.pullFromServer,
          child: _platformDescriptions.isEmpty
              ? const Center(
                  child: Text(
                    "looks like there are no platforms 😔",
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  padding: Defaults.edgeInsets.normal,
                  child: ListView.separated(
                    itemBuilder: (_, index) => PlatformCard(
                      platformDescription: _platformDescriptions[index],
                    ),
                    separatorBuilder: (_, __) =>
                        Defaults.sizedBox.vertical.normal,
                    itemCount: _platformDescriptions.length,
                  ),
                ),
        ),
        drawer: MainDrawer(selectedRoute: Routes.action.platformOverview),
      ),
    );
  }
}

class PlatformCard extends StatelessWidget {
  const PlatformCard({Key? key, required this.platformDescription})
      : super(key: key);

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
                  style: Theme.of(context).textTheme.subtitle1,
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
                  ),
              ],
            ),
            const Divider(),
            for (var actionProvider in platformDescription.actionProviders) ...[
              Defaults.sizedBox.vertical.small,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: !platformDescription.platform.credential ||
                        platformDescription.platformCredential != null
                    ? () => Navigator.of(context).pushNamed(
                          Routes.action.actionProviderOverview,
                          arguments: actionProvider,
                        )
                    : () => showMessageDialog(
                          context: context,
                          text:
                              "Credentials are needed before you can use the action providers.",
                        ),
                child: Row(
                  children: [
                    Text(
                      actionProvider.name,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class PlatformCredentialDialog extends StatefulWidget {
  const PlatformCredentialDialog(this.platformDescription, {Key? key})
      : super(key: key);
  final PlatformDescription platformDescription;

  @override
  State<PlatformCredentialDialog> createState() =>
      _PlatformCredentialDialogState();
}

class _PlatformCredentialDialogState extends State<PlatformCredentialDialog> {
  late PlatformDescription platformDescription;
  final _dataProvider = PlatformDescriptionDataProvider();

  @override
  void initState() {
    platformDescription = widget.platformDescription.clone();
    platformDescription.platformCredential ??= PlatformCredential.defaultValue(
      widget.platformDescription.platform.id,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _usernameInput,
            _passwordInput,
            Defaults.sizedBox.vertical.normal,
            Row(
              children: [
                const SizedBox(width: 39),
                _updateButton,
                const Spacer(),
                _deleteButton,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget get _usernameInput {
    return TextFormField(
      onChanged: (username) {
        setState(
          () => platformDescription.platformCredential!.username = username,
        );
      },
      initialValue: platformDescription.platformCredential!.username,
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.account),
            labelText: "Username",
          ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget get _passwordInput {
    return TextFormField(
      onChanged: (password) {
        setState(
          () => platformDescription.platformCredential!.password = password,
        );
      },
      initialValue: platformDescription.platformCredential!.password,
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.key),
            labelText: "Password",
          ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: TextInputAction.done,
      obscureText: true,
    );
  }

  Widget get _updateButton {
    return ElevatedButton(
      onPressed: _update,
      child: Text(
        widget.platformDescription.platformCredential == null
            ? "Create"
            : "Update",
      ),
    );
  }

  Future<void> _update() async {
    final result = widget.platformDescription.platformCredential == null
        ? await _dataProvider.createSingle(platformDescription)
        : await _dataProvider.updateSingle(platformDescription);
    if (result.isFailure()) {
      await showMessageDialog(
        context: context,
        text: 'Creating Credentials failed:\n${result.failure}',
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget get _deleteButton {
    return ElevatedButton(
      onPressed: _delete,
      child: Text(
        widget.platformDescription.platformCredential == null
            ? "Back"
            : "Delete",
      ),
    );
  }

  Future<void> _delete() async {
    if (widget.platformDescription.platformCredential == null) {
      Navigator.pop(context);
    } else {
      final result = await _dataProvider.deleteSingle(platformDescription);
      if (result.isFailure()) {
        await showMessageDialog(
          context: context,
          text: 'Deleting Credentials failed:\n${result.failure}',
        );
      } else if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
