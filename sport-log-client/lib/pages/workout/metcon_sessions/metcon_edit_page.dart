import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/set_input/new_set_input.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class MetconEditPage extends StatefulWidget {
  const MetconEditPage({
    required this.metconDescription,
    super.key,
  });

  final MetconDescription? metconDescription;
  bool get isNew => metconDescription == null;

  @override
  State<StatefulWidget> createState() => _MetconEditPageState();
}

class _MetconEditPageState extends State<MetconEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final MetconDescription _metconDescription =
      widget.metconDescription?.clone() ?? MetconDescription.defaultValue();
  final _descriptionFocusNode = FocusNode();
  final _dataProvider = MetconDescriptionDataProvider();

  Future<void> _saveMetcon() async {
    if (_metconDescription.metcon.description == "") {
      setState(() => _metconDescription.metcon.description = null);
    }
    final result = widget.isNew
        ? await _dataProvider.createSingle(_metconDescription)
        : await _dataProvider.updateSingle(_metconDescription);
    if (result.isSuccess) {
      MetconDescription.defaultMetconDescription ??= _metconDescription;
      if (mounted) {
        Navigator.pop(
          context,
          // needed for return to details page
          ReturnObject.isNew(widget.isNew, _metconDescription),
        );
      }
    } else if (mounted) {
      await showMessageDialog(
        context: context,
        text:
            "${widget.isNew ? 'Creating' : 'Updating'} Metcon failed:\n${result.failure}",
      );
    }
  }

  Future<void> _deleteMetcon() async {
    final delete = await showDeleteWarningDialog(context, "Metcon");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      assert(_metconDescription.metcon.userId != null);
      assert(!_metconDescription.hasReference);
      final result = await _dataProvider.deleteSingle(_metconDescription);
      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(
            context,
            // needed for return to details page
            ReturnObject.deleted(_metconDescription),
          );
        } else {
          await showMessageDialog(
            context: context,
            text: "Deleting Metcon failed:\n${result.failure}",
          );
        }
      }
    } else if (mounted) {
      Navigator.pop(
        context,
        // needed for return to details page
        ReturnObject.deleted(_metconDescription),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Metcon"),
          actions: [
            if (!_metconDescription.hasReference &&
                _metconDescription.metcon.userId != null)
              IconButton(
                onPressed: _deleteMetcon,
                icon: const Icon(AppIcons.delete),
              ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _metconDescription.isValid()
                  ? _saveMetcon
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
                _nameInput(),
                _descriptionInput(),
                _typeInput(),
                Defaults.sizedBox.vertical.small,
                _additionalFieldsInput(),
                const Divider(thickness: 2),
                _metconMovementsList(),
                _addMetconMovementButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameInput() {
    return TextFormField(
      initialValue: _metconDescription.metcon.name,
      onChanged: (name) =>
          setState(() => _metconDescription.metcon.name = name),
      validator: Validator.validateStringNotEmpty,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.titleLarge,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            labelText: "Name",
          ),
    );
  }

  Widget _descriptionInput() {
    return _metconDescription.metcon.description == null
        ? ActionChip(
            avatar: const Icon(AppIcons.add),
            label: const Text("Add Description"),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _metconDescription.metcon.description = "");
              _descriptionFocusNode.requestFocus();
            },
          )
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              initialValue: _metconDescription.metcon.description ?? "",
              focusNode: _descriptionFocusNode,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: 5,
              onChanged: (description) => setState(
                () => _metconDescription.metcon.description = description,
              ),
              decoration: Theme.of(context).textFormFieldDecoration.copyWith(
                    labelText: "Description",
                    suffixIcon: IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: () => setState(
                        () => _metconDescription.metcon.description = null,
                      ),
                    ),
                  ),
            ),
          );
  }

  Widget _typeInput() {
    return SegmentedButton(
      segments: MetconType.values
          .map(
            (md) => ButtonSegment(
              value: md,
              label: Text(md.name),
            ),
          )
          .toList(),
      selected: {_metconDescription.metcon.metconType},
      showSelectedIcon: false,
      onSelectionChanged: (selected) => _setType(selected.first),
    );
  }

  void _setType(MetconType type) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _metconDescription.metcon.metconType = type;
      switch (type) {
        case MetconType.amrap:
          _metconDescription.metcon.rounds = null;
          _metconDescription.metcon.timecap ??= Metcon.timecapDefaultValue;
        case MetconType.emom:
          _metconDescription.metcon.rounds ??= Metcon.roundsDefaultValue;
          _metconDescription.metcon.timecap ??= Metcon.timecapDefaultValue;
        case MetconType.forTime:
          _metconDescription.metcon.rounds ??= Metcon.roundsDefaultValue;
        // timecap can be either null or non null
      }
    });
  }

  Widget _additionalFieldsInput() {
    return switch (_metconDescription.metcon.metconType) {
      MetconType.amrap => _timecapInput(caption: "Time", allowCancel: false),
      MetconType.emom => Column(
          children: [
            _roundsInput(),
            _timecapInput(caption: "Total Time", allowCancel: false),
          ],
        ),
      MetconType.forTime => Column(
          children: [
            _roundsInput(),
            _timecapInput(caption: "Timecap", allowCancel: true),
          ],
        ),
    };
  }

  Widget _roundsInput() {
    return EditTile(
      leading: AppIcons.timeInterval,
      caption: "Rounds",
      child: IntInput(
        initialValue:
            _metconDescription.metcon.rounds ?? Metcon.roundsDefaultValue,
        minValue: 1,
        maxValue: 999,
        onUpdate: (rounds) {
          setState(() => _metconDescription.metcon.rounds = rounds);
        },
      ),
    );
  }

  Widget _timecapInput({required String caption, required bool allowCancel}) {
    return EditTile.optionalActionChip(
      leading: AppIcons.timeInterval,
      caption: caption,
      showActionChip: _metconDescription.metcon.timecap == null,
      onActionChipTap: () => setState(() {
        _metconDescription.metcon.timecap = Metcon.timecapDefaultValue;
      }),
      builder: () => DurationInput(
        initialDuration: _metconDescription.metcon.timecap ??=
            Metcon.timecapDefaultValue,
        minDuration: const Duration(minutes: 1),
        onUpdate: (timecap) {
          setState(() => _metconDescription.metcon.timecap = timecap);
        },
      ),
      onCancel: allowCancel
          ? () => setState(() => _metconDescription.metcon.timecap = null)
          : null,
    );
  }

  Widget _metconMovementsList() {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final mmd = _metconDescription.moves[index];
        return MetconMovementCard(
          key: ObjectKey(mmd),
          onDelete: () {
            setState(() => _metconDescription.moves.removeAt(index));
          },
          onUpdate: (mmd) {
            setState(() => _metconDescription.moves[index] = mmd);
          },
          mmd: mmd,
        );
      },
      itemCount: _metconDescription.moves.length,
      onReorder: _reorder,
    );
  }

  Widget _addMetconMovementButton() {
    return ActionChip(
      avatar: const Icon(AppIcons.add),
      label: const Text("Add movement"),
      // ignore: prefer-extracting-callbacks
      onPressed: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        final movement = await showMovementPicker(
          selectedMovement: null,
          context: context,
        );
        if (movement != null) {
          _addMetconMovementWithMovement(movement);
        }
      },
    );
  }

  void _addMetconMovementWithMovement(Movement movement) {
    setState(() {
      _metconDescription.moves.add(
        MetconMovementDescription(
          metconMovement: MetconMovement.defaultValue(
            metconId: _metconDescription.metcon.id,
            movementId: movement.id,
            movementNumber: _metconDescription.moves.length,
          ),
          movement: movement,
        ),
      );
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
    final insertAt = oldIndex < newIndex ? newIndex - 1 : newIndex;
    setState(() {
      final oldMove = _metconDescription.moves.removeAt(oldIndex);
      _metconDescription.moves.insert(insertAt, oldMove);
    });
  }
}

class MetconMovementCard extends StatelessWidget {
  const MetconMovementCard({
    required this.onDelete,
    required this.onUpdate,
    required this.mmd,
    super.key,
  });

  final MetconMovementDescription mmd;
  final void Function(MetconMovementDescription) onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  mmd.movement.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(AppIcons.delete),
                  onPressed: onDelete,
                ),
                Defaults.sizedBox.horizontal.big,
                ReorderableDragStartListener(
                  index: mmd.metconMovement.movementNumber,
                  child: const Icon(AppIcons.dragHandle),
                ),
              ],
            ),
            Defaults.sizedBox.vertical.normal,
            NewSetInput(
              onNewSet: (count, weight, secondWeight, distanceUnit) {
                mmd.metconMovement.count = count;
                mmd.metconMovement.maleWeight = weight;
                mmd.metconMovement.femaleWeight = secondWeight;
                mmd.metconMovement.distanceUnit = distanceUnit;
                onUpdate(mmd);
              },
              confirmChanges: false,
              dimension: mmd.movement.dimension,
              editWeightUnit: true,
              distanceUnit: mmd.metconMovement.distanceUnit,
              editDistanceUnit: true,
              initialCount: mmd.metconMovement.count,
              initialWeight: mmd.metconMovement.maleWeight,
              secondWeight: true,
              initialSecondWeight: mmd.metconMovement.femaleWeight,
            ),
          ],
        ),
      ),
    );
  }
}
