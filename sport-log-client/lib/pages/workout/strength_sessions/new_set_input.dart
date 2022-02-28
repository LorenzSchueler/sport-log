import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';
import 'package:sport_log/widgets/app_icons.dart';

class NewSetInput extends StatelessWidget {
  const NewSetInput({
    Key? key,
    required this.dimension,
    required this.onNewSet,
  }) : super(key: key);

  final MovementDimension dimension;
  final void Function(int count, [double? weight]) onNewSet;

  @override
  Widget build(BuildContext context) {
    switch (dimension) {
      case MovementDimension.reps:
        return RepsPicker(setValue: onNewSet); // TODO and weight picker
      case MovementDimension.time:
        return SetDurationInput(onNewSet: onNewSet);
      case MovementDimension.distance:
        // TODO: Handle this case.
        break;
      case MovementDimension.energy:
        // TODO: Handle this case.
        break;
    }
    return Container(
      color: Colors.red,
      width: double.infinity,
      height: 70,
    );
  }
}

class RepsPicker extends StatefulWidget {
  const RepsPicker({
    required this.setValue,
    this.initReps = 0,
    this.stepSize = 1,
    Key? key,
  }) : super(key: key);

  final int initReps;
  final int stepSize;
  final void Function(int count, [double? weight]) setValue;

  @override
  _RepsPickerState createState() => _RepsPickerState();
}

class _RepsPickerState extends State<RepsPicker> {
  int _reps = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Reps ",
          style: Theme.of(context).textTheme.headline5,
        ),
        IntPicker(
          setValue: (reps) => setState(() => _reps = reps),
        ), // TODO init reps
        const Text("<Weight picker to come>"), // TODO
        IconButton(
          icon: const Icon(AppIcons.check),
          color: _reps > 0 ? primaryColorOf(context) : null,
          onPressed: _reps > 0 ? () => widget.setValue(_reps) : null,
        ),
      ],
    );
  }
}
