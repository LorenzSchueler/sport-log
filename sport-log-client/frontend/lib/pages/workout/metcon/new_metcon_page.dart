
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

  bool _advancedOptionsExpanded = false;

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
            });
          },
          child: Text(
            type.toDisplayName(),
            style: style.copyWith(
              color: (type == _metcon.type)
                  ? null
                  : Theme.of(context).disabledColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  _advancedFieldsInput(BuildContext context) {
    return ExpansionPanelList(
      expandedHeaderPadding: EdgeInsets.zero,
      children: [
        ExpansionPanel(
          isExpanded: _advancedOptionsExpanded,
          headerBuilder: (context, isOpen) => const ListTile(
            title: Text("Advanced"),
          ),
          body: Column(
            children: [
              const Padding(padding: EdgeInsets.only(top: 3)),
              if (_metcon.description == null)
                ListTile(
                  title: const Text("Add description ..."),
                  onTap: () {
                    setState(() {
                      _metcon.description = "";
                    });
                  },
                ),
              if (_metcon.description != null)
                _descriptionInput(context),
              if (_metcon.rounds == null)
                ListTile(
                  title: const Text("Add number of rounds ..."),
                  onTap: () {
                    setState(() {
                      _metcon.rounds = 1;
                    });
                  },
                ),
              if (_metcon.rounds != null)
                _roundsInput(context),
              if (_metcon.timecap == null)
                ListTile(
                  title: const Text("Add timecap ..."),
                  onTap: () {
                    setState(() {
                      _metcon.timecap = const Duration(minutes: 21);
                    });
                  },
                ),
              if (_metcon.timecap != null)
                _timecapInput(context),
            ],
          ),
          canTapOnHeader: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ],
      expansionCallback: (_, isExpanded) {
        setState(() {
          _advancedOptionsExpanded = !isExpanded;
        });
      },
      elevation: 0,
    );
  }

  Widget _descriptionInput(BuildContext context) {
    return TextField(
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
    );
  }

  Widget _roundsInput(BuildContext context) {
    return Row(
      children: [
        const Text("Rounds:"),
        IntPicker(
          initialValue: _metcon.rounds ?? 1,
          setValue: (int value) {
            setState(() {
              _metcon.rounds = value;
            });
          },
        ),
      ]
    );
  }

  Widget _timecapInput(BuildContext context) {
    return Row(
      children: [
        const Text("Timecap:"),
      ],
    );
  }
}