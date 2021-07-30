
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
  String _name = "";
  MetconType _type = MetconType.amrap;
  int _rounds = 1;
  Duration? _timecap;
  String? _description;
  List<NewMetconMovement> _moves = [];
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
          _name = name;
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
              _type = type;
            });
          },
          child: Text(
            type.toDisplayName(),
            style: style.copyWith(
              color: (type == _type) ? null : Theme.of(context).disabledColor,
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
              _descriptionInput(context),
              _roundsInput(context),
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
          _description = description;
        });
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Description",
      ),
    );
  }

  Widget _roundsInput(BuildContext context) {
    return Row(
      children: [
        const Text("Rounds:"),
        IntPicker(
          initialValue: _rounds,
          setValue: (int value) {
            setState(() {
              _rounds = value;
            });
          },
        ),
      ]
    );
  }

  Widget _timecapInput(BuildContext context) {
    return const Placeholder(
      fallbackHeight: 50,
    );
  }


}