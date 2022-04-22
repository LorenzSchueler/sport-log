import 'package:flutter/material.dart' hide Action;
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/action/action.dart';
import 'package:sport_log/models/action/action_event.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/action_picker.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';

class ActionEventEditPage extends StatefulWidget {
  const ActionEventEditPage({
    required this.actionProviderDescription,
    required this.actionEvent,
    Key? key,
  }) : super(key: key);

  final ActionProviderDescription actionProviderDescription;
  final ActionEvent? actionEvent;

  @override
  State<ActionEventEditPage> createState() => _ActionEventEditPageState();
}

class _ActionEventEditPageState extends State<ActionEventEditPage> {
  final _dataProvider = ActionEventDataProvider();
  late ActionEvent _actionEvent;

  @override
  void initState() {
    _actionEvent = widget.actionEvent?.clone() ??
        ActionEvent(
          id: randomId(),
          userId: Settings.userId!,
          actionId: widget.actionProviderDescription.actions.first.id,
          datetime: DateTime.now(),
          arguments: null,
          enabled: true,
          deleted: false,
        );
    super.initState();
  }

  Future<void> _saveActionEvent() async {
    final result = widget.actionEvent != null
        ? await _dataProvider.updateSingle(_actionEvent)
        : await _dataProvider.createSingle(_actionEvent);
    if (result.isSuccess()) {
      Navigator.pop(context);
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Action Event failed:\n${result.failure}',
      );
    }
  }

  Future<void> _deleteActionEvent() async {
    if (widget.actionEvent != null) {
      await _dataProvider.deleteSingle(_actionEvent);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.actionEvent != null
              ? "Edit Action Event"
              : "Create Action Event",
        ),
        leading: IconButton(
          onPressed: () async {
            final approved = await showDiscardWarningDialog(context);
            if (approved) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(AppIcons.arrowBack),
        ),
        actions: [
          IconButton(
            onPressed: _deleteActionEvent,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _actionEvent.isValid() ? _saveActionEvent : null,
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
                    .where((action) => action.id == _actionEvent.actionId)
                    .first
                    .name,
              ),
              onTap: () async {
                Action? action = await showActionPicker(
                  actions: widget.actionProviderDescription.actions,
                  context: context,
                );
                if (action != null) {
                  setState(() => _actionEvent.actionId = action.id);
                }
              },
            ),
            EditTile(
              caption: 'Date',
              child: Text(_actionEvent.datetime.toHumanDateTime()),
              leading: AppIcons.calendar,
              onTap: () async {
                final datetime = await showDateTimePicker(
                  context: context,
                  initial: _actionEvent.datetime,
                );
                if (datetime != null) {
                  setState(() {
                    _actionEvent.datetime = datetime;
                  });
                }
              },
            ),
            TextFormField(
              decoration: Theme.of(context).textFormFieldDecoration.copyWith(
                    icon: const Icon(AppIcons.comment),
                    labelText: "Arguments",
                  ),
              initialValue: _actionEvent.arguments,
              onChanged: (arguments) =>
                  _actionEvent.arguments = arguments.isEmpty ? null : arguments,
            ),
          ],
        ),
      ),
    );
  }
}
