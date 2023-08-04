import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/action/action_provider.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

String actionName(
  ActionProviderDescription actionProviderDescription,
  Int64 actionId,
) =>
    actionProviderDescription.actions
        .firstWhere((action) => action.id == actionId)
        .name;

class ActionProviderOverviewPage extends StatefulWidget {
  const ActionProviderOverviewPage({required this.actionProvider, super.key});

  final ActionProvider actionProvider;

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
    _dataProvider.addListener(_update);
    _update();
    super.initState();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    super.dispose();
  }

  Future<void> _update() async {
    _logger.d("updating action provider page");
    final actionProviderDescription =
        await _dataProvider.getByActionProvider(widget.actionProvider);
    if (mounted) {
      if (actionProviderDescription == null) {
        await showMessageDialog(
          context: context,
          title: "Info",
          text: "Action provider was deleted.",
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _actionProviderDescription = actionProviderDescription);
      }
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
          : SyncRefreshIndicator(
              child: Padding(
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
    );
  }
}

class ActionsCard extends StatelessWidget {
  const ActionsCard({required this.actionProviderDescription, super.key});

  final ActionProviderDescription actionProviderDescription;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ProviderConsumer(
          create: (_) => BoolToggle.off(),
          builder: (context, expanded, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CaptionTile(caption: "Actions"),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: expanded.toggle,
                    icon: Icon(
                      expanded.isOn ? AppIcons.arrowUp : AppIcons.arrowDown,
                    ),
                  ),
                ],
              ),
              if (expanded.isOn) ...[
                for (final action in actionProviderDescription.actions) ...[
                  const Divider(),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(action.name),
                      ),
                      Defaults.sizedBox.horizontal.normal,
                      Expanded(child: Text(action.description ?? "")),
                    ],
                  ),
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class ActionRulesCard extends StatelessWidget {
  ActionRulesCard({required this.actionProviderDescription, super.key});

  final ActionProviderDescription actionProviderDescription;
  final _dataProvider = ActionRuleDataProvider();

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
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.actionRuleEdit,
                    arguments: [actionProviderDescription, null],
                  ),
                  icon: const Icon(AppIcons.add),
                ),
              ],
            ),
            for (final actionRule in actionProviderDescription.actionRules) ...[
              const Divider(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.actionRuleEdit,
                  arguments: [actionProviderDescription, actionRule],
                ),
                child: Column(
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
                          "${actionRule.weekday.name} at ${actionRule.time.hourMinute}",
                        ),
                        const Spacer(),
                        Checkbox(
                          visualDensity: VisualDensity.compact,
                          value: actionRule.enabled,
                          onChanged: (value) {
                            if (value != null) {
                              actionRule.enabled = value;
                              _dataProvider.updateSingle(actionRule);
                            }
                          },
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
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class ActionEventsCard extends StatelessWidget {
  ActionEventsCard({required this.actionProviderDescription, super.key});

  final ActionProviderDescription actionProviderDescription;
  final _dataProvider = ActionEventDataProvider();

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
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.actionEventEdit,
                    arguments: [actionProviderDescription, null],
                  ),
                  icon: const Icon(AppIcons.add),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            for (final actionEvent
                in actionProviderDescription.actionEvents) ...[
              const Divider(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.actionEventEdit,
                  arguments: [actionProviderDescription, actionEvent],
                ),
                child: Column(
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
                          actionEvent.datetime.humanDateTime,
                        ),
                        const Spacer(),
                        Checkbox(
                          value: actionEvent.enabled,
                          onChanged: (value) {
                            if (value != null) {
                              actionEvent.enabled = value;
                              _dataProvider.updateSingle(actionEvent);
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
