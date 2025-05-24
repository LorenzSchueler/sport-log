import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/sync_status_button.dart';

class MovementEditPage extends StatefulWidget {
  const MovementEditPage({required this.movementDescription, super.key})
    : name = null;

  const MovementEditPage.fromName({required String this.name, super.key})
    : movementDescription = null;

  final MovementDescription? movementDescription;
  final String? name;
  bool get isNew => movementDescription == null;

  @override
  State<StatefulWidget> createState() => _MovementEditPageState();
}

class _MovementEditPageState extends State<MovementEditPage> {
  final _dataProvider = MovementDataProvider();
  final _formKey = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();
  late final MovementDescription _movementDescription;

  @override
  void initState() {
    _movementDescription =
        widget.movementDescription?.clone() ??
        MovementDescription.defaultValue();
    if (widget.name != null) {
      _movementDescription.movement.name = widget.name!;
    }

    super.initState();
  }

  Future<void> _saveMovement() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(_movementDescription.movement)
        : await _dataProvider.updateSingle(_movementDescription.movement);
    if (result.isOk) {
      await _dataProvider.setDefaultMovement();
      if (mounted) {
        Navigator.pop(context);
      }
    } else if (mounted) {
      await showMessageDialog(
        context: context,
        title: "${widget.isNew ? 'Creating' : 'Updating'} Movement Failed",
        text: result.err.toString(),
      );
    }
  }

  Future<void> _deleteMovement() async {
    final delete = await showDeleteWarningDialog(context, "Movement");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      assert(!_movementDescription.movement.isDefaultMovement);
      assert(!_movementDescription.hasReference);
      final result = await _dataProvider.deleteSingle(
        _movementDescription.movement,
      );
      if (mounted) {
        if (result.isOk) {
          Navigator.pop(context);
        } else {
          await showMessageDialog(
            context: context,
            title: "Deleting Movement Failed",
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
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Movement"),
          actions: [
            if (!_movementDescription.hasReference)
              IconButton(
                onPressed: _deleteMovement,
                icon: const Icon(AppIcons.delete),
              ),
            IconButton(
              onPressed:
                  _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _movementDescription.isValidBeforeSanitation()
                  ? _saveMovement
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (Settings.instance.developerMode)
                  SyncStatusButton(
                    entity: _movementDescription.movement,
                    dataProvider: MovementDataProvider(),
                  ),
                TextFormField(
                  initialValue: _movementDescription.movement.name,
                  onChanged: (name) {
                    if (Validator.validateStringNotEmpty(name) == null) {
                      setState(() => _movementDescription.movement.name = name);
                    }
                  },
                  validator: Validator.validateStringNotEmpty,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    icon: Icon(AppIcons.movement),
                    labelText: "Name",
                  ),
                ),
                OptionalTextFormField(
                  textFormField: TextFormField(
                    initialValue: _movementDescription.movement.description,
                    focusNode: _descriptionFocusNode,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (description) => setState(
                      () => _movementDescription.movement.description =
                          description,
                    ),
                    decoration: InputDecoration(
                      icon: const Icon(AppIcons.notes),
                      labelText: "Description",
                      suffixIcon: IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: () => setState(
                          () =>
                              _movementDescription.movement.description = null,
                        ),
                      ),
                    ),
                  ),
                  showTextFormField:
                      _movementDescription.movement.description != null,
                  leading: AppIcons.notes,
                  buttonText: "Description",
                  onButtonPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _movementDescription.movement.description = "";
                    });
                    _descriptionFocusNode.requestFocus();
                  },
                ),
                Defaults.sizedBox.vertical.small,
                SegmentedButton(
                  segments: MovementDimension.values
                      .map(
                        (md) => ButtonSegment(value: md, label: Text(md.name)),
                      )
                      .toList(),
                  selected: {_movementDescription.movement.dimension},
                  showSelectedIcon: false,
                  onSelectionChanged: (selected) => setState(
                    () => _movementDescription.movement.dimension =
                        selected.first,
                  ),
                ),
                CheckboxListTile(
                  value: _movementDescription.movement.cardio,
                  checkColor: Theme.of(context).colorScheme.onPrimary,
                  onChanged: (bool? isCardio) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (isCardio != null) {
                      setState(
                        () => _movementDescription.movement.cardio = isCardio,
                      );
                    }
                  },
                  title: const Text('Is suitable for cardio sessions'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
