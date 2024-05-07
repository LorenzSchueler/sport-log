import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/wod_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/wod/wod.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class WodEditPage extends StatefulWidget {
  const WodEditPage({this.wod, super.key});

  final Wod? wod;
  bool get isNew => wod == null;

  @override
  State<WodEditPage> createState() => _WodEditPageState();
}

class _WodEditPageState extends State<WodEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = WodDataProvider();

  late final Wod _wod = widget.wod?.clone() ?? Wod.defaultValue();

  Future<void> _saveWod() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(_wod)
        : await _dataProvider.updateSingle(_wod);
    if (mounted) {
      if (result.isOk) {
        Navigator.pop(context);
      } else {
        await showMessageDialog(
          context: context,
          title: "${widget.isNew ? 'Creating' : 'Updating'} Wod Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _deleteWod() async {
    final delete = await showDeleteWarningDialog(context, "Wod");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result = await _dataProvider.deleteSingle(_wod);
      if (mounted) {
        if (result.isOk) {
          Navigator.pop(context);
        } else {
          await showMessageDialog(
            context: context,
            title: "Deleting Wod Failed",
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
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Wod"),
          actions: [
            IconButton(
              onPressed: _deleteWod,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _wod.isValidBeforeSanitation()
                  ? _saveWod
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                EditTile(
                  leading: AppIcons.calendar,
                  caption: "Date",
                  child: Text(_wod.date.humanDate),
                  onTap: () async {
                    final date = await showDatePickerWithDefaults(
                      context: context,
                      initialDate: _wod.date,
                    );
                    if (mounted && date != null) {
                      setState(() {
                        _wod.date = date;
                      });
                    }
                  },
                ),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      icon: Icon(AppIcons.notes),
                      labelText: "Description",
                    ),
                    initialValue: _wod.description,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onChanged: (description) => setState(() {
                      _wod.description =
                          description.isEmpty ? null : description;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
