import 'package:flutter/material.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/models/strength/strength_set.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/box_int_input.dart';

class SetDurationInput extends StatefulWidget {
  const SetDurationInput({Key? key, required this.onNewSet}) : super(key: key);

  final ChangeCallback<StrengthSet> onNewSet;

  @override
  _SetDurationInputState createState() => _SetDurationInputState();
}

class _SetDurationInputState extends State<SetDurationInput> {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _milliseconds = 0;

  final _hoursKey = GlobalKey<BoxIntInputState>();
  final _minutesKey = GlobalKey<BoxIntInputState>();
  final _secondsKey = GlobalKey<BoxIntInputState>();
  final _millisecondsKey = GlobalKey<BoxIntInputState>();

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
    return IconButton(
      icon: const Icon(Icons.check),
      color: primaryColorOf(context),
      iconSize: BoxIntInput.textFontSize,
      onPressed: () {
        final duration = Duration(
          hours: _hours,
          minutes: _minutes,
          seconds: _seconds,
          milliseconds: _milliseconds,
        );
        print(duration);
      },
    );
  }

  Widget get _timeInput {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: BoxIntInput.textFontSize),
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
    return BoxIntInput(
      key: _hoursKey,
      placeholder: 0,
      caption: 'h',
      numberOfDigits: 2,
      onChanged: (value) => _hours = value,
      onSubmitted: () => _minutesKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _minutesInput {
    return BoxIntInput(
      key: _minutesKey,
      placeholder: 0,
      caption: 'm',
      numberOfDigits: 2,
      maxValue: 59,
      onChanged: (value) => _minutes = value,
      onSubmitted: () => _secondsKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _secondsInput {
    return BoxIntInput(
      key: _secondsKey,
      placeholder: 0,
      caption: 's',
      numberOfDigits: 2,
      onChanged: (value) => _seconds = value,
      onSubmitted: () => _millisecondsKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _millisecondsInput {
    return BoxIntInput(
      key: _millisecondsKey,
      placeholder: 0,
      caption: 'ms',
      numberOfDigits: 3,
      onChanged: (value) => _milliseconds = value,
    );
  }
}
