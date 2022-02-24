import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/box_int_input.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SetDurationInput extends StatefulWidget {
  const SetDurationInput({Key? key, required this.onNewSet}) : super(key: key);

  final void Function(int count, [double? weight]) onNewSet;

  @override
  _SetDurationInputState createState() => _SetDurationInputState();
}

class _SetDurationInputState extends State<SetDurationInput> {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _milliseconds = 0;

  final _hoursKey = GlobalKey<PaddedIntInputState>();
  final _minutesKey = GlobalKey<PaddedIntInputState>();
  final _secondsKey = GlobalKey<PaddedIntInputState>();
  final _millisecondsKey = GlobalKey<PaddedIntInputState>();

  void _submit() {
    final duration = Duration(
      hours: _hours,
      minutes: _minutes,
      seconds: _seconds,
      milliseconds: _milliseconds,
    );
    widget.onNewSet(duration.inMilliseconds);

    // clear all inputs
    _hoursKey.currentState?.clear();
    _minutesKey.currentState?.clear();
    _secondsKey.currentState?.clear();
    _millisecondsKey.currentState?.clear();

    // request focus on the right input
    if ((_hoursKey.currentState?.hasFocus ?? false) ||
        (_minutesKey.currentState?.hasFocus ?? false) ||
        (_secondsKey.currentState?.hasFocus ?? false) ||
        (_millisecondsKey.currentState?.hasFocus ?? false)) {
      if (duration.inHours != 0) {
        _hoursKey.currentState?.requestFocus();
      } else if (duration.inMinutes != 0) {
        _minutesKey.currentState?.requestFocus();
      } else if (duration.inSeconds != 0) {
        _secondsKey.currentState?.requestFocus();
      } else if (duration.inMilliseconds != 0) {
        _millisecondsKey.currentState?.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _timeInput,
        const Spacer(),
        _addButton,
      ],
    );
  }

  Widget get _addButton {
    final isSubmittable =
        _hours != 0 || _minutes != 0 || _seconds != 0 || _milliseconds != 0;
    return IconButton(
      icon: const Icon(AppIcons.check),
      color: isSubmittable ? primaryColorOf(context) : null,
      iconSize: PaddedIntInput.fontSize,
      onPressed: isSubmittable ? _submit : null,
    );
  }

  Widget get _timeInput {
    return DefaultTextStyle(
      style: TextStyle(fontSize: PaddedIntInput.fontSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _hoursInput,
          const Text(':'),
          _minutesInput,
          const Text(':'),
          _secondsInput,
          const Text(','),
          _millisecondsInput,
        ],
      ),
    );
  }

  Widget get _hoursInput {
    return PaddedIntInput(
      key: _hoursKey,
      placeholder: 0,
      caption: 'h',
      numberOfDigits: 2,
      onChanged: (value) => setState(() => _hours = value),
      onSubmitted: () => _minutesKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _minutesInput {
    return PaddedIntInput(
      key: _minutesKey,
      placeholder: 0,
      caption: 'm',
      numberOfDigits: 2,
      maxValue: 59,
      onChanged: (value) => setState(() => _minutes = value),
      onSubmitted: () => _secondsKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _secondsInput {
    return PaddedIntInput(
      key: _secondsKey,
      placeholder: 0,
      caption: 's',
      numberOfDigits: 2,
      onChanged: (value) => setState(() => _seconds = value),
      onSubmitted: () => _millisecondsKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _millisecondsInput {
    return PaddedIntInput(
      key: _millisecondsKey,
      placeholder: 0,
      caption: 'ms',
      numberOfDigits: 3,
      onChanged: (value) => setState(() => _milliseconds = value),
    );
  }
}
