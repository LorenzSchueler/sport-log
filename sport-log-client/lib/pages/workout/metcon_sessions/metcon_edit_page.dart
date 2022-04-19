import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/strength_sessions/new_set_input.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/input_fields/selection_bar.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

class MetconEditPage extends StatefulWidget {
  const MetconEditPage({
    Key? key,
    this.metconDescription,
  }) : super(key: key);

  final MetconDescription? metconDescription;

  @override
  State<StatefulWidget> createState() => _MetconEditPageState();
}

class _MetconEditPageState extends State<MetconEditPage> {
  final _logger = Logger('EditMetconPage');
  final _formKey = GlobalKey<FormState>();
  late final MetconDescription _metconDescription;
  final _descriptionFocusNode = FocusNode();
  final _dataProvider = MetconDescriptionDataProvider();

  @override
  void initState() {
    _logger.i("got ${widget.metconDescription}");
    _metconDescription =
        widget.metconDescription?.clone() ?? MetconDescription.defaultValue();
    super.initState();
  }

  Future<void> _saveMetcon() async {
    if (_metconDescription.metcon.description == "") {
      setState(() => _metconDescription.metcon.description = null);
    }
    final result = widget.metconDescription != null
        ? await _dataProvider.updateSingle(_metconDescription)
        : await _dataProvider.createSingle(_metconDescription);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      Navigator.pop(
        context,
        ReturnObject(
          action: widget.metconDescription != null
              ? ReturnAction.updated
              : ReturnAction.created,
          payload: _metconDescription,
        ), // needed for return to details page
      );
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Metcon failed:\n${result.failure}',
      );
    }
  }

  Future<void> _deleteMetcon() async {
    if (widget.metconDescription != null) {
      await _dataProvider.deleteSingle(_metconDescription);
    }
    Navigator.pop(
      context,
      ReturnObject(action: ReturnAction.deleted, payload: _metconDescription),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.metconDescription != null ? "Edit Metcon" : "New Metcon",
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
              onPressed: _metconDescription.hasReference ? null : _deleteMetcon,
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
        body: Container(
          padding: Defaults.edgeInsets.normal,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _nameInput(context),
                _descriptionInput(),
                _typeInput(),
                _additionalFieldsInput(),
                const Divider(thickness: 2),
                _metconMovementsList(),
                _addMetconMovementButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      initialValue: _metconDescription.metcon.name,
      onChanged: (name) =>
          setState(() => _metconDescription.metcon.name = name),
      validator: Validator.validateStringNotEmpty,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.headline6,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: "Name",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
    );
  }

  Widget _descriptionInput() {
    return _metconDescription.metcon.description == null
        ? ActionChip(
            avatar: const Icon(AppIcons.add),
            label: const Text("Add Description"),
            onPressed: () {
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
              onChanged: (description) => setState(
                () => _metconDescription.metcon.description = description,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
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
    return SelectionBar<MetconType>(
      onChange: _setType,
      items: MetconType.values,
      getLabel: (metconType) => metconType.displayName,
      selectedItem: _metconDescription.metcon.metconType,
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
          break;
        case MetconType.emom:
          _metconDescription.metcon.rounds ??= Metcon.roundsDefaultValue;
          _metconDescription.metcon.timecap ??= Metcon.timecapDefaultValue;
          break;
        case MetconType.forTime:
          _metconDescription.metcon.rounds ??= Metcon.roundsDefaultValue;
          // timecap can be either null or non null
          break;
      }
    });
  }

  Widget _additionalFieldsInput() {
    switch (_metconDescription.metcon.metconType) {
      case MetconType.amrap:
        return _timecapInput(caption: "Time");
      case MetconType.emom:
        return Column(
          children: [
            _roundsInput(),
            _timecapInput(caption: "Total Time"),
          ],
        );
      case MetconType.forTime:
        return Column(
          children: [
            _roundsInput(),
            _maybeTimecapInput(),
          ],
        );
    }
  }

  Widget _roundsInput() {
    return EditTile(
      leading: AppIcons.timeInterval,
      caption: "Rounds",
      child: IntInput(
        initialValue:
            _metconDescription.metcon.rounds ?? Metcon.roundsDefaultValue,
        setValue: (rounds) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _metconDescription.metcon.rounds = rounds);
        },
      ),
    );
  }

  Widget _timecapInput({required String caption, void Function()? onCancel}) {
    return EditTile(
      leading: AppIcons.timeInterval,
      caption: caption,
      child: DurationInput(
        initialDuration: _metconDescription.metcon.timecap ??=
            Metcon.timecapDefaultValue,
        setDuration: (timecap) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _metconDescription.metcon.timecap = timecap);
        },
      ),
      onCancel: onCancel,
    );
  }

  Widget _maybeTimecapInput() {
    return _metconDescription.metcon.timecap == null
        ? ActionChip(
            avatar: const Icon(AppIcons.add),
            label: const Text("Add Timecap"),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(
                () => _metconDescription.metcon.timecap =
                    Metcon.timecapDefaultValue,
              );
            },
          )
        : _timecapInput(
            caption: "Timecap",
            onCancel: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _metconDescription.metcon.timecap = null);
            },
          );
  }

  Widget _metconMovementsList() {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final move = _metconDescription.moves[index];
        return MetconMovementCard(
          key: ObjectKey(move),
          deleteMetconMovement: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _metconDescription.moves.removeAt(index));
          },
          editMetconMovementDescription: (mmd) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _metconDescription.moves[index] = mmd);
          },
          mmd: move,
        );
      },
      itemCount: _metconDescription.moves.length,
      onReorder: (int oldIndex, int newIndex) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        setState(() {
          final oldMove = _metconDescription.moves.removeAt(oldIndex);
          _metconDescription.moves.insert(newIndex, oldMove);
        });
      },
    );
  }

  Widget _addMetconMovementButton(BuildContext context) {
    return ActionChip(
      avatar: const Icon(AppIcons.add),
      label: const Text("Add movement"),
      onPressed: () async {
        final movement = await showMovementPicker(context: context);
        if (movement != null) {
          _addMetconMovementWithMovement(movement);
        }
      },
    );
  }

  void _addMetconMovementWithMovement(Movement movement) {
    FocusManager.instance.primaryFocus?.unfocus();
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
}

class MetconMovementCard extends StatelessWidget {
  const MetconMovementCard({
    required this.deleteMetconMovement,
    required this.editMetconMovementDescription,
    required this.mmd,
    Key? key,
  }) : super(key: key);

  final MetconMovementDescription mmd;
  final void Function(MetconMovementDescription) editMetconMovementDescription;
  final void Function() deleteMetconMovement;

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
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(AppIcons.delete),
                  onPressed: deleteMetconMovement,
                ),
                Defaults.sizedBox.horizontal.big,
                ReorderableDragStartListener(
                  child: const Icon(AppIcons.dragHandle),
                  index: mmd.metconMovement.movementNumber,
                ),
              ],
            ),
            Defaults.sizedBox.vertical.normal,
            NewSetInput(
              onNewSet: (count, weight, secondWeight) {
                mmd.metconMovement.count = count;
                mmd.metconMovement.maleWeight = weight;
                mmd.metconMovement.femaleWeight = secondWeight;
                editMetconMovementDescription(mmd);
              },
              confirmChanges: false,
              dimension: mmd.movement.dimension,
              distanceUnit: mmd.metconMovement.distanceUnit,
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
