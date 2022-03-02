import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/form_widgets/double_picker.dart';
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
        return RepWeightPicker(setValue: onNewSet);
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

class RepWeightPicker extends StatefulWidget {
  const RepWeightPicker({
    required this.setValue,
    Key? key,
  }) : super(key: key);

  final void Function(int count, [double? weight]) setValue;

  @override
  _RepWeightPickerState createState() => _RepWeightPickerState();
}

class _RepWeightPickerState extends State<RepWeightPicker> {
  int _reps = 0;
  double? _weight;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Table(
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FixedColumnWidth(85),
            2: FixedColumnWidth(166),
          },
          children: [
            TableRow(
              children: [
                Container(),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Text(
                    "Reps ",
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
                IntPicker(
                  setValue: (reps) => setState(() => _reps = reps),
                ),
              ],
            ),
            TableRow(
              children: _weight == null
                  ? [
                      IconButton(
                        icon: const Icon(AppIcons.add),
                        onPressed: () => setState(() => _weight = 0),
                        padding: EdgeInsets.zero,
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(
                          "Weight ",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      Container(),
                    ]
                  : [
                      IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: () => setState(() => _weight = null),
                        padding: EdgeInsets.zero,
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(
                          "Weight ",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      DoublePicker(
                        setValue: (weight) => setState(() => _weight = weight),
                      )
                    ],
            )
          ],
        ),
        Defaults.sizedBox.horizontal.big,
        IconButton(
          icon: const Icon(AppIcons.check),
          color: _reps > 0 ? primaryColorOf(context) : null,
          onPressed: _reps > 0 ? () => widget.setValue(_reps, _weight) : null,
        ),
      ],
    );
  }
}
