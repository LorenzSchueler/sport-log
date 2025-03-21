import 'package:flutter/material.dart' hide Action;
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/action/action_event.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class ActionEventEditPage extends StatefulWidget {
  const ActionEventEditPage({
    required this.actionProviderDescription,
    required this.actionEvent,
    super.key,
  });

  final ActionProviderDescription actionProviderDescription;
  final ActionEvent? actionEvent;
  bool get isNew => actionEvent == null;

  @override
  State<ActionEventEditPage> createState() => _ActionEventEditPageState();
}

class _ActionEventEditPageState extends State<ActionEventEditPage> {
  final _dataProvider = ActionEventDataProvider();
  late final ActionEvent _actionEvent =
      widget.actionEvent?.clone() ??
      ActionEvent.defaultValue(
        widget.actionProviderDescription.actions.first.id,
      );

  Future<void> _saveActionEvent() async {
    final result =
        widget.isNew
            ? await _dataProvider.createSingle(_actionEvent)
            : await _dataProvider.updateSingle(_actionEvent);
    if (mounted) {
      if (result.isOk) {
        Navigator.pop(context);
      } else {
        await showMessageDialog(
          context: context,
          title:
              "${widget.isNew ? 'Creating' : 'Updating'} Action Event Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _deleteActionEvent() async {
    final delete = await showDeleteWarningDialog(context, "Action Event");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result = await _dataProvider.deleteSingle(_actionEvent);
      if (mounted) {
        if (result.isOk) {
          Navigator.pop(context);
        } else {
          await showMessageDialog(
            context: context,
            title: "Deleting Action Event Failed",
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
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Action Event"),
          actions: [
            IconButton(
              onPressed: _deleteActionEvent,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed:
                  _actionEvent.isValidBeforeSanitation()
                      ? _saveActionEvent
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
                      .where((action) => action.id == _actionEvent.actionId)
                      .first
                      .name,
                ),
                onTap: () async {
                  final action = await showActionPicker(
                    actions: widget.actionProviderDescription.actions,
                    selectedAction: widget.actionProviderDescription.actions
                        .firstWhere(
                          (action) => action.id == _actionEvent.actionId,
                        ),
                    context: context,
                  );
                  if (mounted && action != null) {
                    setState(() => _actionEvent.actionId = action.id);
                  }
                },
              ),
              EditTile(
                caption: 'Date',
                leading: AppIcons.calendar,
                onTap: () async {
                  final datetime = await showDateTimePicker(
                    context: context,
                    initial: _actionEvent.datetime,
                    future: true,
                  );
                  if (mounted && datetime != null) {
                    setState(() {
                      _actionEvent.datetime = datetime;
                    });
                  }
                },
                child: Text(_actionEvent.datetime.humanDateTime),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.comment),
                  labelText: "Arguments",
                ),
                initialValue: _actionEvent.arguments,
                onChanged:
                    (arguments) => setState(() {
                      _actionEvent.arguments =
                          arguments.isEmpty ? null : arguments;
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
