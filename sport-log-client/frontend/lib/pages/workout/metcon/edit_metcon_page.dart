
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/helpers/pluralize.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/metcon/ui_metcon.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/metcon/metcon_request_bloc.dart';
import 'package:sport_log/widgets/int_picker.dart';
import 'package:sport_log/widgets/loading_dialog.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'metcon_movement_card.dart';

class EditMetconPage extends StatefulWidget {

  EditMetconPage({
    Key? key,
    UiMetcon? initialMetcon,
  }) : _initialMetcon = initialMetcon, super(key: key) {
    if (initialMetcon != null) {
      assert(_initialMetcon!.id != null);
    }
  }
  
  final UiMetcon? _initialMetcon;

  @override
  State<StatefulWidget> createState() => _EditMetconPageState(_initialMetcon);

  bool get _isEditing => _initialMetcon != null;
}

class _EditMetconPageState extends State<EditMetconPage> {

  static const _timecapDefaultValue = Duration(minutes: 20);
  static const _roundsDefaultValue = 1;
  static const _countDefaultValue = 5;
  static const _unitDefaultValue = MovementUnit.reps;
  static const _typeDefaultValue = MetconType.amrap;

  _EditMetconPageState(UiMetcon? metcon)
    : _metcon = metcon ?? UiMetcon(
    type: _typeDefaultValue,
    deleted: false,
  );
  
  final UiMetcon _metcon;

  final _descriptionFocusNode = FocusNode();
  
  _setName(String name) {
    setState(() => _metcon.name = name);
  }
  
  _setType(MetconType type) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _metcon.type = type;
      switch (type) {
        case MetconType.amrap:
          _metcon.rounds = null;
          _metcon.timecap ??= _timecapDefaultValue;
          break;
        case MetconType.emom:
          _metcon.rounds ??= _roundsDefaultValue;
          _metcon.timecap ??= _timecapDefaultValue;
          break;
        case MetconType.forTime:
          _metcon.rounds ??= _roundsDefaultValue;
          // timecap can be either null or non null
          break;
      }
    });
  }

  _setRounds(int? rounds) {
    // TODO: assert consistent state
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _metcon.rounds = rounds);
  }

  _setTimecap(Duration? timecap) {
    // TODO: assert consistent state
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _metcon.timecap = timecap);
  }
  
  _setDescription(String? description) {
    setState(() => _metcon.description = description);
  }

  _removeMetconMovement(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _metcon.moves.removeAt(index));
  }

  _setMetconMovement(int index, UiMetconMovement mm) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _metcon.moves[index] = mm);
  }

  _reorderMetconMovements(int oldIndex, int newIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final oldMove = _metcon.moves.removeAt(oldIndex);
      _metcon.moves.insert(newIndex, oldMove);
    });
  }

  _addMetconMovementWithMovementId(Int64 movementId) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _metcon.moves.add(UiMetconMovement(
        movementId: movementId,
        count: _countDefaultValue,
        unit: _unitDefaultValue,
        deleted: false,
      ));
    });
  }

  bool _inputIsValid() {
    return _metcon.name != null
        && _metcon.name != ""
        && _metcon.moves.isNotEmpty;
  }

  _submit(MetconRequestBloc requestBloc) {
    if (!_inputIsValid()) {
      return;
    }
    if (_metcon.description == "") {
      setState(() => _metcon.description = null);
    }
    if (widget._isEditing) {
      requestBloc.add(MetconRequestUpdate(_metcon));
    } else {
      requestBloc.add(MetconRequestCreate(_metcon));
    }
  }

  _delete(MetconRequestBloc requestBloc) {
    if (widget._isEditing) {
      assert(_metcon.id != null);
      requestBloc.add(MetconRequestDelete(_metcon.id!));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestBloc = MetconRequestBloc.fromContext(context);
    return BlocConsumer<MetconRequestBloc, MetconRequestState>(
      bloc: requestBloc,
      listener: (context, state) {
        if (state is MetconRequestFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.reason.toErrorMessage()),)
          );
        } else if (state is MetconRequestSucceeded) {
          // FIXME: this feels kinda unsafe
          Navigator.of(context).pop(); // remove loading indicator
          Navigator.of(context).pop(); // go back to metcons page
        } else if (state is MetconRequestPending) {
          showDialog(
            context: context,
            builder: (context) => const LoadingDialog(),
          );
        }
      },
      builder: (context, state) => _buildForm(context, requestBloc),
    );
  }

  Widget _buildForm(BuildContext context, MetconRequestBloc requestBloc) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._isEditing ? "Edit Metcon" : "New Metcon"),
          leading: IconButton(
            onPressed: _inputIsValid() ? () => _submit(requestBloc) : null,
            icon: const Icon(Icons.save),
          ),
          actions: [
            IconButton(
              onPressed: () => _delete(requestBloc),
              icon: const Icon(Icons.delete),
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
      initialValue: _metcon.name ?? "",
      onChanged: _setName,
      style: Theme.of(context).textTheme.headline6,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: "Name",
        border: OutlineInputBorder(),
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
            type.toDisplayName(),
            style: style.copyWith(
              color: (type == _metcon.type)
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _additionalFieldsInput(BuildContext context) {
    switch (_metcon.type) {
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
        Text(plural("min", "mins", _metcon.timecap?.inMinutes ?? 0)
            + " in total"),
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
            Text(plural("round", "rounds", _metcon.rounds ?? 0)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("in"),
            _timecapInput(context),
            Text(plural("min", "mins", _metcon.timecap?.inMinutes ?? 0)),
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
            Text(plural("round", "rounds", _metcon.rounds ?? 0)),
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
        initialValue: _metcon.description ?? "",
        focusNode: _descriptionFocusNode,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        onChanged: _setDescription,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Description",
          suffixIcon: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () => _setDescription(null),
          ),
        ),
      ),
    );
  }

  Widget _maybeDescriptionInput(BuildContext context) {
    if (_metcon.description == null) {
      return OutlinedButton.icon(
          onPressed: () {
            _setDescription("");
            _descriptionFocusNode.requestFocus();
          },
          icon: const Icon(Icons.add),
          label: const Text("Add description..."),
      );
    } else {
      return _descriptionInput(context);
    }
  }

  Widget _roundsInput(BuildContext context) {
    return IntPicker(
      initialValue: _metcon.rounds ?? _roundsDefaultValue,
      setValue: _setRounds,
    );
  }

  Widget _timecapInput(BuildContext context) {
    return IntPicker(
      initialValue: _metcon.timecap?.inMinutes
          ?? _timecapDefaultValue.inMinutes,
      setValue: (int value) => _setTimecap(Duration(minutes: value)),
    );
  }

  Widget _maybeTimecapInput(BuildContext context) {
    if (_metcon.timecap == null) {
      return OutlinedButton.icon(
        onPressed: () => _setTimecap(_timecapDefaultValue),
        icon: const Icon(Icons.add),
        label: const Text("Add timecap..."),
      );
    } else { // _metcon.timecap != null
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("in"),
              _timecapInput(context),
              Text(plural("min", "mins", _metcon.timecap?.inMinutes ?? 0)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () => _setTimecap(null),
          ),
        ]
      );
    }
  }

  Widget _metconMovementsList(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final move = _metcon.moves[index];
        return MetconMovementCard(
          key: ObjectKey(move),
          index: index,
          deleteMetconMovement: () => _removeMetconMovement(index),
          editMetconMovement: (mm) => _setMetconMovement(index, mm),
          move: move,
        );
      },
      itemCount: _metcon.moves.length,
      onReorder: _reorderMetconMovements,
    );
  }

  Widget _addMetconMovementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => MetconMovementCard
          .showMovementPickerDialog(context, _addMetconMovementWithMovementId),
      icon: const Icon(Icons.add),
      label: const Text("Add movement..."),
    );
  }
}