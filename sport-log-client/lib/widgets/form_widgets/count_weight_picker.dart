import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/widgets/form_widgets/double_picker.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CountWeightPicker extends StatefulWidget {
  const CountWeightPicker({
    required this.setValue,
    required this.countLabel,
    this.countUnit,
    Key? key,
  }) : super(key: key);

  final String countLabel;
  final String? countUnit;
  final void Function(int count, [double? weight]) setValue;

  @override
  _CountWeightPickerState createState() => _CountWeightPickerState();
}

class _CountWeightPickerState extends State<CountWeightPicker> {
  int _count = 0;
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
            1: FixedColumnWidth(140),
            2: FixedColumnWidth(166),
          },
          children: [
            TableRow(
              children: [
                Container(),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Text(
                    widget.countUnit == null
                        ? widget.countLabel
                        : "${widget.countLabel} (${widget.countUnit!})",
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
                IntPicker(
                  setValue: (count) => setState(() => _count = count),
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
        Defaults.sizedBox.horizontal.normal,
        IconButton(
          icon: const Icon(AppIcons.check),
          iconSize: 40,
          color: _count > 0 ? primaryColorOf(context) : null,
          onPressed: _count > 0 ? () => widget.setValue(_count, _weight) : null,
        ),
      ],
    );
  }
}
