import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/platform/platform_credential.dart';
import 'package:sport_log/models/platform/platform_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';

final _dataProvider = PlatformDescriptionDataProvider();

class PlatformOverviewPage extends StatefulWidget {
  const PlatformOverviewPage({Key? key}) : super(key: key);

  @override
  State<PlatformOverviewPage> createState() => PlatformOverviewPageState();
}

class PlatformOverviewPageState extends State<PlatformOverviewPage> {
  final _logger = Logger('PlatformOverviewPage');
  List<PlatformDescription> _platformDescriptions = [];

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
    return Scaffold(
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
    );
  }
}

class PlatformCard extends StatefulWidget {
  final PlatformDescription platformDescription;

  const PlatformCard({Key? key, required this.platformDescription})
      : super(key: key);

  @override
  State<PlatformCard> createState() => PlatformCardState();
}

class PlatformCardState extends State<PlatformCard> {
  final _logger = Logger('PlatfromCard');
  late PlatformDescription platformDescription;
  bool credentialsExpanded = false;
  bool actionProviderExpanded = false;

  @override
  void initState() {
    platformDescription = widget.platformDescription;
    if (platformDescription.platform.credential) {
      platformDescription.platformCredential ??= PlatformCredential(
        id: randomId(),
        userId: Settings.userId!,
        platformId: widget.platformDescription.platform.id,
        username: "",
        password: "",
        deleted: false,
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(
                () => actionProviderExpanded = !actionProviderExpanded,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    platformDescription.platform.name,
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (platformDescription.platform.credential)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(
                        () => credentialsExpanded = !credentialsExpanded,
                      ),
                      icon: const Icon(AppIcons.settings),
                    ),
                ],
              ),
            ),
            if (credentialsExpanded) ...[
              const Divider(),
              _usernameInput,
              _passwordInput,
              Center(child: _submitButton),
            ],
            if (actionProviderExpanded) ...[
              const Divider(),
              const Text("action provider list"),
            ],
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
      initialValue: platformDescription.platformCredential?.username,
      decoration: const InputDecoration(
        icon: Icon(AppIcons.account),
        labelText: "Username",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
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
      initialValue: platformDescription.platformCredential?.password,
      decoration: const InputDecoration(
        icon: Icon(AppIcons.key),
        labelText: "Password",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: TextInputAction.done,
      obscureText: true,
    );
  }

  Widget get _submitButton {
    return ElevatedButton(
      child: const Text(
        "Update",
        style: TextStyle(fontSize: 18),
      ), // TODO: use theme for this
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: Defaults.borderRadius.big,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _logger.i(platformDescription);

    final result = widget.platformDescription.platformCredential == null
        ? await _dataProvider.createSingle(platformDescription)
        : await _dataProvider.updateSingle(platformDescription);
    if (result.isFailure()) {
      await showMessageDialog(
        context: context,
        text: 'Creating Credentials failed:\n${result.failure}',
      );
    }
  }
}
