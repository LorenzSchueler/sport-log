
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/models/metcon.dart';
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
                _advancedFieldsInput(context),
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

  Widget _advancedFieldsInput(BuildContext context) {
    switch (_metcon.type) {
      case MetconType.amrap:
        return Row(
          children: [
            const Text("Timecap:"),
            _timecapInput(context),
            const Text("mins"),
          ],
        );
      case MetconType.emom:
        return Row(
          children: [
            _roundsInput(context),
            const Text("rounds in"),
            _timecapInput(context),
            const Text("mins"),
          ],
        );
      case MetconType.forTime:
        return Row(
          children: [
            _roundsInput(context),
            const Text("rounds in"),
            _maybeTimecapInput(context),
            const Text("mins"),
          ],
        );
    }
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

  Widget _timecapInput(BuildContext context, { bool isDismissible = false }) {
    return Row(
      children: [
        IntPicker(
          initialValue: _metcon.timecap?.inMinutes ?? _timecapDefaultValue.inMinutes,
          setValue: (int value) {
            setState(() {
              _metcon.timecap = Duration(minutes: value);
            });
          },
        ),
        if (isDismissible)
          IconButton(
              onPressed: () {
                setState(() {
                  _metcon.timecap = null;
                });
              },
              icon: const Icon(Icons.cancel)
          ),
      ],
    );
  }

  Widget _maybeTimecapInput(BuildContext context) {
    if (_metcon.timecap == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _metcon.timecap = _timecapDefaultValue;
          });
        },
        label: const Text("Add timecap..."),
      );
    } else {
      return _timecapInput(context, isDismissible: true);
    }
  }
}