import 'package:flutter/material.dart' hide Action;
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/action/action_rule.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class ActionRuleEditPage extends StatefulWidget {
  const ActionRuleEditPage({
    required this.actionProviderDescription,
    required this.actionRule,
    super.key,
  });

  final ActionProviderDescription actionProviderDescription;
  final ActionRule? actionRule;
  bool get isNew => actionRule == null;

  @override
  State<ActionRuleEditPage> createState() => _ActionRuleEditPageState();
}

class _ActionRuleEditPageState extends State<ActionRuleEditPage> {
  final _dataProvider = ActionRuleDataProvider();
  late final ActionRule _actionRule =
      widget.actionRule?.clone() ??
      ActionRule.defaultValue(
        widget.actionProviderDescription.actions.first.id,
      );

  Future<void> _saveActionRule() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(_actionRule)
        : await _dataProvider.updateSingle(_actionRule);
    if (mounted) {
      if (result.isOk) {
        Navigator.pop(context);
      } else {
        await showMessageDialog(
          context: context,
          title: "${widget.isNew ? 'Creating' : 'Updating'} Action Rule Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _deleteActionRule() async {
    final delete = await showDeleteWarningDialog(context, "Action Rule");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result = await _dataProvider.deleteSingle(_actionRule);
      if (mounted) {
        if (result.isOk) {
          Navigator.pop(context);
        } else {
          await showMessageDialog(
            context: context,
            title: "Deleting Action Rule Failed",
            text: result.err.toString(),
          );
        }
      }
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Action Rule"),
          actions: [
            IconButton(
              onPressed: _deleteActionRule,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _actionRule.isValidBeforeSanitation()
                  ? _saveActionRule
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Padding(
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
                  final action = await showActionPicker(
                    actions: widget.actionProviderDescription.actions,
                    selectedAction: widget.actionProviderDescription.actions
                        .firstWhere(
                          (action) => action.id == _actionRule.actionId,
                        ),
                    context: context,
                  );
                  if (mounted && action != null) {
                    setState(() => _actionRule.actionId = action.id);
                  }
                },
              ),
              EditTile(
                leading: AppIcons.calendar,
                caption: "Weekday",
                child: Text(_actionRule.weekday.name),
                onTap: () async {
                  final weekday = await showWeekdayPicker(
                    selectedWeekday: _actionRule.weekday,
                    context: context,
                  );
                  if (mounted && weekday != null) {
                    setState(() => _actionRule.weekday = weekday);
                  }
                },
              ),
              EditTile(
                leading: AppIcons.clock,
                caption: "Time",
                child: Text(_actionRule.time.hourMinute),
                onTap: () async {
                  final time = await showScrollableTimePicker(
                    context: context,
                    initialTime: _actionRule.time,
                  );
                  if (mounted && time != null) {
                    setState(() => _actionRule.time = time);
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.comment),
                  labelText: "Arguments",
                ),
                initialValue: _actionRule.arguments,
                onChanged: (arguments) => setState(() {
                  _actionRule.arguments = arguments.isEmpty ? null : arguments;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
