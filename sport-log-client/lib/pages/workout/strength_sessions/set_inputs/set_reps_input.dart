import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';

import 'box_int_input.dart';

class SetRepsInput extends StatefulWidget {
  const SetRepsInput({
    Key? key,
    required this.onNewSet,
  }) : super(key: key);

  final void Function(int count, [double? weight]) onNewSet;

  @override
  _SetRepsInputState createState() => _SetRepsInputState();
}

class _SetRepsInputState extends State<SetRepsInput> {
  int reps = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _repsInput,
        const Spacer(),
        _addButton,
      ],
    );
  }

  Widget get _addButton {
    final isSubmittable = reps != 0;
    return IconButton(
      icon: const Icon(AppIcons.check),
      color: isSubmittable ? primaryColorOf(context) : null,
      iconSize: UnrestrictedIntInput.fontSize,
      onPressed: isSubmittable ? _submit : null,
    );
  }

  Widget get _repsInput {
    return DefaultTextStyle(
      style: TextStyle(fontSize: UnrestrictedIntInput.fontSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          UnrestrictedIntInput(
            placeholder: 0,
            onChanged: (value) => setState(() => reps = value),
            caption: 'Reps',
            width: 100,
          ),
        ],
      ),
    );
  }

  void _submit() {
    assert(reps > 0);
    widget.onNewSet(reps);
  }
}
