
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  static const _weightDefaultValue = 10.0;

  final _descriptionFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("New Metcon"),
          leading: IconButton(
            onPressed: _inputIsValid() ? () {
              Navigator.of(context).pop(_metcon);
            } : null,
            icon: const Icon(Icons.save),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete),
            )
          ],
        ),
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
                _metconMovementsList(context),
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

  Widget _metconMovementsList(BuildContext context) {
    return ReorderableListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final move = _metcon.moves[index];
        return Card(
          key: ObjectKey(move),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          child: Column(
            children: [
              ListTile(
                title: Text(
                    context.read<MovementRepository>()
                        .getMovement(move.movementId)!.name
                ),
                onTap: () => _showMovementPickerDialog(context, (id) {
                  setState(() {
                    _metcon.moves[index].movementId = id;
                  });
                }),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _metcon.moves.removeAt(index);
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntPicker(initialValue: move.count, setValue: (count) {
                    setState(() {
                      move.count = count;
                    });
                  }),
                  const Padding(padding: EdgeInsets.all(8)),
                  DropdownButton(
                    value: move.unit,
                    onChanged: (MovementUnit? u) {
                      if (u != null) {
                        setState(() {
                          move.unit = u;
                        });
                      }
                    },
                    items: MovementUnit.values.map((u) =>
                        DropdownMenuItem(
                          child: Text(u.toDisplayName()),
                          key: ValueKey(u.toString()),
                          value: u,
                        )
                    ).toList(),
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (move.weight == null)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          move.weight = _weightDefaultValue;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add weight..."),
                    ),
                  if (move.weight != null)
                    const Text("Float picker to come"),
                ],
              ),
            ],
          ),
        );
      },
      itemCount: _metcon.moves.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        setState(() {
          final oldMove = _metcon.moves.removeAt(oldIndex);
          _metcon.moves.insert(newIndex, oldMove);
        });
      }
    );
  }

  void _showMovementPickerDialog(BuildContext context, Function(int) onPicked) {
    showDialog(
        context: context,
        builder: (_) => const MovementPickerDialog(),
    ).then((movementId) {
      if (movementId is int) {
        onPicked(movementId);
      }
    });
  }

  Widget _addMetconMovementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showMovementPickerDialog(context, (id) {
        setState(() {
          _metcon.moves.add(NewMetconMovement(
            movementId: id,
            count: _countDefaultValue,
            unit: _unitDefaultValue,
          ));
        });
      }),
      icon: const Icon(Icons.add),
      label: const Text("Add movement..."),
    );
  }

  bool _inputIsValid() {
    return _metcon.name != "" && _metcon.moves.isNotEmpty;
  }
}