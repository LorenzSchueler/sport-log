import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';

class DurationPicker extends StatefulWidget {
  const DurationPicker(
      {Key? key, required this.setValue, required this.initialValue})
      : super(key: key);

  final void Function(Duration) setValue;
  final Duration initialValue;

  @override
  State<StatefulWidget> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late Duration value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _minutesInput(context),
        const Text('m'),
        _secondsInput(context),
        const Text('s'),
      ],
    );
  }

  Widget _minutesInput(BuildContext context) {
    return Column(
      children: [
        _addButton(context, () {}),
        _minutesTextField(context),
        _subtractButton(context, () {}),
      ],
    );
  }

  Widget _secondsInput(BuildContext context) {
    return Column(
      children: [
        _addButton(context, () {}),
        _secondsTextField(context),
        _subtractButton(context, () {}),
      ],
    );
  }

  Widget _addButton(BuildContext context, void Function() onPressed) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onPressed,
      icon: const Icon(Icons.add_box_rounded),
      color: primaryColorOf(context),
    );
  }

  Widget _subtractButton(BuildContext context, void Function() onPressed) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onPressed,
      icon: const Icon(Icons.indeterminate_check_box_rounded),
      color: primaryColorOf(context),
    );
  }

  Widget _minutesTextField(BuildContext context) {
    return SizedBox(
      width: 40,
      child: TextFormField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _secondsTextField(BuildContext context) {
    return SizedBox(
      width: 40,
      child: TextFormField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

/*
  void _setValue(Duration d) {
    setState(() {
      value = d;
    });
    widget.setValue(d);
  }

  void _setMinutes(int m) {
    assert(m >= 0);
    if (m >= 0) {
      _setValue(Duration(minutes: m, seconds: value.inSeconds % 60));
    }
  }

  void _setSeconds(int s) {
    assert(s >= 0 && s < 60);
    if (s >= 0 && s < 60) {
      _setValue(Duration(minutes: value.inMinutes, seconds: s));
    }
  }
   */
}
