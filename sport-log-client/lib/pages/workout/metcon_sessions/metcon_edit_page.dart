import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'metcon_movement_card.dart';

class EditMetconPage extends StatefulWidget {
  const EditMetconPage({
    Key? key,
    MetconDescription? initialMetcon,
  })  : _initialMetcon = initialMetcon,
        super(key: key);

  final MetconDescription? _initialMetcon;

  @override
  State<StatefulWidget> createState() => _EditMetconPageState();

  bool get _isEditing => _initialMetcon != null;
}

class _EditMetconPageState extends State<EditMetconPage> {
  late final MetconDescription _md;
  final _descriptionFocusNode = FocusNode();
  final _dataProvider = MetconDescriptionDataProvider.instance;

  @override
  void initState() {
    super.initState();
    _md = widget._initialMetcon ??
        MetconDescription.defaultValue(Settings.userId!);
  }

  void _setName(String name) {
    setState(() => _md.metcon.name = name);
  }

  void _setType(MetconType type) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _md.metcon.metconType = type;
      switch (type) {
        case MetconType.amrap:
          _md.metcon.rounds = null;
          _md.metcon.timecap ??= Metcon.timecapDefaultValue;
          break;
        case MetconType.emom:
          _md.metcon.rounds ??= Metcon.roundsDefaultValue;
          _md.metcon.timecap ??= Metcon.timecapDefaultValue;
          break;
        case MetconType.forTime:
          _md.metcon.rounds ??= Metcon.roundsDefaultValue;
          // timecap can be either null or non null
          break;
      }
    });
  }

  void _setRounds(int? rounds) {
    // TODO: assert consistent state
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _md.metcon.rounds = rounds);
  }

  void _setTimecap(Duration? timecap) {
    // TODO: assert consistent state
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _md.metcon.timecap = timecap);
  }

  void _setDescription(String? description) {
    setState(() => _md.metcon.description = description);
  }

  void _removeMetconMovement(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _md.moves.removeAt(index));
  }

  void _setMetconMovementDescription(int index, MetconMovementDescription mmd) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _md.moves[index] = mmd);
  }

  void _reorderMetconMovements(int oldIndex, int newIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final oldMove = _md.moves.removeAt(oldIndex);
      _md.moves.insert(newIndex, oldMove);
    });
  }

  void _addMetconMovementWithMovement(Movement movement) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _md.moves.add(MetconMovementDescription(
          metconMovement: MetconMovement.defaultValue(
              metconId: _md.metcon.id,
              movementId: movement.id,
              movementNumber: _md.moves.length),
          movement: movement));
    });
  }

  void _submit() async {
    if (!_md.isValid()) {
      return;
    }
    if (_md.metcon.description == "") {
      setState(() => _md.metcon.description = null);
    }
    if (widget._isEditing) {
      await _dataProvider.updateSingle(_md);
      Navigator.pop(
          context, ReturnObject(action: ReturnAction.updated, payload: _md));
    } else {
      await _dataProvider.createSingle(_md);
      Navigator.pop(
          context, ReturnObject(action: ReturnAction.created, payload: _md));
    }
  }

  void _delete() async {
    if (widget._isEditing) {
      await _dataProvider.deleteSingle(_md);
      Navigator.pop(
          context, ReturnObject(action: ReturnAction.deleted, payload: _md));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._isEditing ? "Edit Metcon" : "New Metcon"),
          leading: IconButton(
            onPressed: _md.isValid() ? _submit : null,
            icon: const Icon(AppIcons.save),
          ),
          actions: [
            IconButton(
              onPressed: _md.hasReference ? null : _delete,
              icon: const Icon(AppIcons.delete),
            )
          ],
        ),
        body: WideScreenFrame(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              child: ListView(
                children: [
                  _nameInput(context),
                  _maybeDescriptionInput(context),
                  _typeInput(context),
                  _additionalFieldsInput(context),
                  const Divider(thickness: 2),
                  _metconMovementsList(context),
                  _addMetconMovementButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      initialValue: _md.metcon.name ?? "",
      onChanged: _setName,
      style: Theme.of(context).textTheme.headline6,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: "Name",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
    );
  }

  Widget _typeInput(BuildContext context) {
    final style = Theme.of(context).textTheme.button!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MetconType.values.map((type) {
        return TextButton(
          onPressed: () => _setType(type),
          child: Text(
            type.displayName,
            style: style.copyWith(
              color: (type == _md.metcon.metconType)
                  ? primaryColorOf(context)
                  : Theme.of(context).disabledColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _additionalFieldsInput(BuildContext context) {
    switch (_md.metcon.metconType) {
      case MetconType.amrap:
        return _amrapInputs(context);
      case MetconType.emom:
        return _emomInputs(context);
      case MetconType.forTime:
        return _forTimeInputs(context);
    }
  }

  Widget _amrapInputs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timecapInput(context),
        Text(plural("min", "mins", _md.metcon.timecap?.inMinutes ?? 0) +
            " in total"),
      ],
    );
  }

  Widget _emomInputs(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundsInput(context),
            Text(plural("round", "rounds", _md.metcon.rounds ?? 0)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("in"),
            _timecapInput(context),
            Text(plural("min", "mins", _md.metcon.timecap?.inMinutes ?? 0)),
          ],
        )
      ],
    );
  }

  Widget _forTimeInputs(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundsInput(context),
            Text(plural("round", "rounds", _md.metcon.rounds ?? 0)),
          ],
        ),
        _maybeTimecapInput(context),
      ],
    );
  }

  Widget _descriptionInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        initialValue: _md.metcon.description ?? "",
        focusNode: _descriptionFocusNode,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        onChanged: _setDescription,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          labelText: "Description",
          suffixIcon: IconButton(
            icon: const Icon(AppIcons.cancel),
            onPressed: () => _setDescription(null),
          ),
        ),
      ),
    );
  }

  Widget _maybeDescriptionInput(BuildContext context) {
    if (_md.metcon.description == null) {
      return OutlinedButton.icon(
        onPressed: () {
          _setDescription("");
          _descriptionFocusNode.requestFocus();
        },
        icon: const Icon(AppIcons.add),
        label: const Text("Add description..."),
      );
    } else {
      return _descriptionInput(context);
    }
  }

  Widget _roundsInput(BuildContext context) {
    return IntPicker(
      initialValue: _md.metcon.rounds ?? Metcon.roundsDefaultValue,
      setValue: _setRounds,
    );
  }

  Widget _timecapInput(BuildContext context) {
    return IntPicker(
      initialValue:
          (_md.metcon.timecap ??= Metcon.timecapDefaultValue).inMinutes,
      setValue: (int value) => _setTimecap(Duration(minutes: value)),
    );
  }

  Widget _maybeTimecapInput(BuildContext context) {
    if (_md.metcon.timecap == null) {
      return OutlinedButton.icon(
        onPressed: () => _setTimecap(Metcon.timecapDefaultValue),
        icon: const Icon(AppIcons.add),
        label: const Text("Add timecap..."),
      );
    } else {
      // _metcon.timecap != null
      return Stack(alignment: Alignment.centerRight, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("in"),
            _timecapInput(context),
            Text(plural("min", "mins", _md.metcon.timecap!.inMinutes)),
          ],
        ),
        IconButton(
          icon: const Icon(AppIcons.cancel),
          onPressed: () => _setTimecap(null),
        ),
      ]);
    }
  }

  Widget _metconMovementsList(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final move = _md.moves[index];
        return MetconMovementCard(
          key: ObjectKey(move),
          deleteMetconMovement: () => _removeMetconMovement(index),
          editMetconMovementDescription: (mm) =>
              _setMetconMovementDescription(index, mm),
          mmd: move,
        );
      },
      itemCount: _md.moves.length,
      onReorder: _reorderMetconMovements,
    );
  }

  Widget _addMetconMovementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final movement = await showMovementPickerDialog(context);
        if (movement != null) {
          _addMetconMovementWithMovement(movement);
        }
      },
      icon: const Icon(AppIcons.add),
      label: const Text("Add movement..."),
    );
  }
}
