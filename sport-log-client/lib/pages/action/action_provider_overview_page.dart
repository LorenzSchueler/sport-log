import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/action/action_provider.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/action/weekday.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';

String actionName(
  ActionProviderDescription actionProviderDescription,
  Int64 actionId,
) =>
    actionProviderDescription.actions
        .where((action) => action.id == actionId)
        .first
        .name;

class ActionProviderOverviewPage extends StatefulWidget {
  final ActionProvider actionProvider;

  const ActionProviderOverviewPage({required this.actionProvider, Key? key})
      : super(key: key);

  @override
  State<ActionProviderOverviewPage> createState() =>
      _ActionProviderOverviewPageState();
}

class _ActionProviderOverviewPageState
    extends State<ActionProviderOverviewPage> {
  final _logger = Logger('ActionProviderOverviewPage');
  final _dataProvider = ActionProviderDescriptionDataProvider();
  ActionProviderDescription? _actionProviderDescription;

  @override
  void initState() {
    _dataProvider
      ..addListener(_update)
      ..onNoInternetConnection =
          () => showSimpleToast(context, 'No Internet connection.');
    _update();
    super.initState();
  }

  @override
  void dispose() {
    _dataProvider
      ..removeListener(_update)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d('Updating action provider page');
    final actionProviderDescription =
        await _dataProvider.getByActionProvider(widget.actionProvider);
    if (actionProviderDescription == null) {
      await showMessageDialog(
        context: context,
        text: "Action Provider was deleted.",
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _actionProviderDescription = actionProviderDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.actionProvider.name} Actions"),
      ),
      body: _actionProviderDescription == null
          ? const CircularProgressIndicator()
          : RefreshIndicator(
              onRefresh: _dataProvider.pullFromServer,
              child: Container(
                padding: Defaults.edgeInsets.normal,
                child: ListView(
                  children: [
                    ActionsCard(
                      actionProviderDescription: _actionProviderDescription!,
                    ),
                    Defaults.sizedBox.vertical.normal,
                    ActionRulesCard(
                      actionProviderDescription: _actionProviderDescription!,
                    ),
                    Defaults.sizedBox.vertical.normal,
                    ActionEventsCard(
                      actionProviderDescription: _actionProviderDescription!,
                    ),
                  ],
                ),
              ),
            ),
      drawer: MainDrawer(selectedRoute: Routes.action.actionProviderOverview),
    );
  }
}

class ActionsCard extends StatelessWidget {
  final ActionProviderDescription actionProviderDescription;
  const ActionsCard({required this.actionProviderDescription, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CaptionTile(caption: "Actions"),
            for (final action in actionProviderDescription.actions) ...[
              const Divider(),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(action.name),
                  ),
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(child: Text(action.description ?? "--")),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class ActionRulesCard extends StatelessWidget {
  final ActionProviderDescription actionProviderDescription;
  const ActionRulesCard({required this.actionProviderDescription, Key? key})
      : super(key: key);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CaptionTile(caption: "Action Rules"),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(Routes.action.actionRuleEdit),
                  icon: const Icon(AppIcons.add),
                ),
              ],
            ),
            for (final actionRule in actionProviderDescription.actionRules) ...[
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          actionName(
                            actionProviderDescription,
                            actionRule.actionId,
                          ),
                        ),
                      ),
                      Defaults.sizedBox.horizontal.normal,
                      Text(
                        "${actionRule.weekday.toDisplayName()} at ${actionRule.time.toStringHourMinute()}",
                      ),
                      const Spacer(),
                      Checkbox(
                        value: actionRule.enabled,
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    ],
                  ),
                  if (actionRule.arguments != null)
                    Row(
                      children: [
                        const SizedBox(width: 120),
                        Defaults.sizedBox.horizontal.normal,
                        Text("Arguments: ${actionRule.arguments}"),
                      ],
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class ActionEventsCard extends StatelessWidget {
  final ActionProviderDescription actionProviderDescription;
  const ActionEventsCard({required this.actionProviderDescription, Key? key})
      : super(key: key);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CaptionTile(caption: "Action Events"),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(Routes.action.actionEventEdit),
                  icon: const Icon(AppIcons.add),
                ),
              ],
            ),
            for (final actionEvent
                in actionProviderDescription.actionEvents) ...[
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          actionName(
                            actionProviderDescription,
                            actionEvent.actionId,
                          ),
                        ),
                      ),
                      Defaults.sizedBox.horizontal.normal,
                      Text(
                        actionEvent.datetime.toHumanWithTime(),
                      ),
                      const Spacer(),
                      Checkbox(
                        value: actionEvent.enabled,
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    ],
                  ),
                  if (actionEvent.arguments != null)
                    Row(
                      children: [
                        const SizedBox(width: 120),
                        Defaults.sizedBox.horizontal.normal,
                        Text("Arguments: ${actionEvent.arguments}"),
                      ],
                    ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
