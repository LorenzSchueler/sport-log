
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/helpers/iterable_extension.dart';
import 'package:sport_log/helpers/pluralize.dart';
import 'package:sport_log/models/metcon.dart';
import 'package:sport_log/models/movement.dart';
import 'package:sport_log/pages/workout/metcon/movement_picker_dialog.dart';
import 'package:sport_log/repositories/movement_repository.dart';
import 'package:sport_log/widgets/int_picker.dart';

class NewMetconPage extends StatefulWidget {
  const NewMetconPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewMetconPageState();
}

class _NewMetconPageState extends State<NewMetconPage> {
  final _metcon = NewMetcon(
      name: "",
      type: MetconType.amrap,
      moves: [],
  );

  static const _timecapDefaultValue = Duration(minutes: 20);
  static const _roundsDefaultValue = 1;
  static const _countDefaultValue = 5;
  static const _unitDefaultValue = MovementUnit.reps;

  final _descriptionFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text("New Metcon")),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: ListView(
              children: [
                _nameInput(context),
                _maybeDescriptionInput(context),
                _typeInput(context),
                _additionalFieldsInput(context),
                const Divider(thickness: 2),
                ..._metconMovementsList(context),
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
      onChanged: (name) {
        setState(() {
          _metcon.name = name;
        });
      },
      style: Theme.of(context).textTheme.headline6,
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
          onPressed: () {
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
          },
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
      child: TextField(
        focusNode: _descriptionFocusNode,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        onChanged: (description) {
          setState(() {
            _metcon.description = description;
          });
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Description",
          suffixIcon: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              setState(() {
                _metcon.description = null;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _maybeDescriptionInput(BuildContext context) {
    if (_metcon.description == null) {
      return OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _metcon.description ??= "";
            });
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
      initialValue: _metcon.rounds ?? 1,
      setValue: (int value) {
        setState(() {
          _metcon.rounds = value;
        });
      },
    );
  }

  Widget _timecapInput(BuildContext context) {
    return IntPicker(
      initialValue: _metcon.timecap?.inMinutes ?? _timecapDefaultValue.inMinutes,
      setValue: (int value) {
        setState(() {
          _metcon.timecap = Duration(minutes: value);
        });
      },
    );
  }

  Widget _maybeTimecapInput(BuildContext context) {
    if (_metcon.timecap == null) {
      return OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _metcon.timecap = _timecapDefaultValue;
          });
        },
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
            onPressed: () {
              setState(() {
                _metcon.timecap = null;
              });
            },
          ),
        ]
      );
    }
  }

  List<Widget> _metconMovementsList(BuildContext context) {
    return _metcon.moves.mapIndexed((index, move) {
      return Card(
        child: Column(
          children: [
            if (move.movementId < 0)
              ElevatedButton(
                onPressed: () => _showMovementPickerDialog(context, index),
                child: const Text("Choose movement..."),
              ),
            if (move.movementId >= 0)
              ListTile(
                title: Text(
                  context.read<MovementRepository>()
                      .getMovement(move.movementId)!.name
                ),
                onTap: () => _showMovementPickerDialog(context, index),
              ),
          ],
        ),
      );
    }).toList();
  }

  void _showMovementPickerDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (_) => const MovementPickerDialog(),
    ).then((movementId) {
      if (movementId is int) {
        setState(() {
          _metcon.moves[index].movementId = movementId;
        });
      }
    });
  }

  Widget _addMetconMovementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _metcon.moves.add(NewMetconMovement(
            movementId: -1,
            count: _countDefaultValue,
            unit: _unitDefaultValue
          ));
        });
      },
      icon: const Icon(Icons.add),
      label: const Text("Add movement..."),
    );
  }
}