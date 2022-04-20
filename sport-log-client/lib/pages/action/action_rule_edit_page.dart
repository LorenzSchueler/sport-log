import 'package:flutter/material.dart' hide Action;
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/action/action.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/action/action_rule.dart';
import 'package:sport_log/models/action/weekday.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/action_picker.dart';
import 'package:sport_log/widgets/picker/time_picker.dart';
import 'package:sport_log/widgets/picker/weekday_picker.dart';

class ActionRuleEditPage extends StatefulWidget {
  const ActionRuleEditPage({
    required this.actionProviderDescription,
    required this.actionRule,
    Key? key,
  }) : super(key: key);

  final ActionProviderDescription actionProviderDescription;
  final ActionRule? actionRule;

  @override
  State<ActionRuleEditPage> createState() => _ActionRuleEditPageState();
}

class _ActionRuleEditPageState extends State<ActionRuleEditPage> {
  final _dataProvider = ActionRuleDataProvider();
  late ActionRule _actionRule;

  @override
  void initState() {
    _actionRule = widget.actionRule?.clone() ??
        ActionRule(
          id: randomId(),
          userId: Settings.userId!,
          actionId: widget.actionProviderDescription.actions.first.id,
          weekday: Weekday.monday,
          time: DateTime.now(),
          arguments: null,
          enabled: true,
          deleted: false,
        );
    super.initState();
  }

  Future<void> _saveActionRule() async {
    final result = widget.actionRule != null
        ? await _dataProvider.updateSingle(_actionRule)
        : await _dataProvider.createSingle(_actionRule);
    if (result.isSuccess()) {
      Navigator.pop(context);
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Action Rule failed:\n${result.failure}',
      );
    }
  }

  Future<void> _deleteActionRule() async {
    if (widget.actionRule != null) {
      await _dataProvider.deleteSingle(_actionRule);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.actionRule != null ? "Edit Action Rule" : "Create Action Rule",
        ),
        leading: IconButton(
          onPressed: () async {
            final bool? approved = await showDiscardWarningDialog(context);
            if (approved != null && approved) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(AppIcons.arrowBack),
        ),
        actions: [
          IconButton(
            onPressed: _deleteActionRule,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _actionRule.isValid() ? _saveActionRule : null,
            icon: const Icon(AppIcons.save),
          ),
        ],
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: ListView(
          children: [
            EditTile(
              leading: AppIcons.radio,
              caption: "Action",
              child: Text(
                widget.actionProviderDescription.actions
                    .where((action) => action.id == _actionRule.actionId)
                    .first
                    .name,
              ),
              onTap: () async {
                Action? action = await showActionPicker(
                  actions: widget.actionProviderDescription.actions,
                  context: context,
                );
                if (action != null) {
                  setState(() => _actionRule.actionId = action.id);
                }
              },
            ),
            EditTile(
              leading: AppIcons.calendar,
              caption: "Weekday",
              child: Text(_actionRule.weekday.displayName),
              onTap: () async {
                Weekday? weekday = await showWeekdayPicker(context: context);
                if (weekday != null) {
                  setState(() => _actionRule.weekday = weekday);
                }
              },
            ),
            EditTile(
              leading: AppIcons.clock,
              caption: "Time",
              child: Text(_actionRule.time.formatTime),
              onTap: () async {
                DateTime? time = await showScrollableTimePicker(
                  context: context,
                  initialTime: _actionRule.time,
                );
                if (time != null) {
                  setState(() => _actionRule.time = time);
                }
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(AppIcons.comment),
                labelText: "Arguments",
                contentPadding: EdgeInsets.symmetric(vertical: 5),
              ),
              initialValue: _actionRule.arguments,
              keyboardType: TextInputType.multiline,
              onChanged: (arguments) =>
                  _actionRule.arguments = arguments.isEmpty ? null : arguments,
            ),
          ],
        ),
      ),
    );
  }
}
