import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CountWeightInput extends StatefulWidget {
  const CountWeightInput({
    required this.setValue,
    required this.confirmChanges,
    required this.countLabel,
    this.countUnit,
    this.initialCount = 0,
    this.initialWeight,
    Key? key,
  }) : super(key: key);

  final void Function(int count, double? weight) setValue;
  final bool confirmChanges;
  final String countLabel;
  final String? countUnit;
  final int initialCount;
  final double? initialWeight;

  @override
  _CountWeightInputState createState() => _CountWeightInputState();
}

class _CountWeightInputState extends State<CountWeightInput> {
  late int _count;
  late double? _weight;

  @override
  void initState() {
    _count = widget.initialCount;
    _weight = widget.initialWeight;
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IntInput(
                  initialValue: _count,
                  setValue: (count) {
                    if (count > 0) {
                      setState(() => _count = count);
                      if (!widget.confirmChanges) {
                        widget.setValue(_count, _weight);
                      }
                    }
                  },
                ),
              ],
            ),
            TableRow(
              children: _weight == null
                  ? [
                      IconButton(
                        icon: const Icon(AppIcons.add),
                        onPressed: () {
                          setState(() => _weight = 0);
                          if (!widget.confirmChanges) {
                            widget.setValue(_count, _weight);
                          }
                        },
                        padding: EdgeInsets.zero,
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(
                          "Weight ",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Container(),
                    ]
                  : [
                      IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: () {
                          setState(() => _weight = null);
                          if (!widget.confirmChanges) {
                            widget.setValue(_count, _weight);
                          }
                        },
                        padding: EdgeInsets.zero,
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(
                          "Weight ",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      DoubleInput(
                        initialValue: _weight!,
                        setValue: (weight) {
                          setState(() => _weight = weight);
                          if (!widget.confirmChanges) {
                            widget.setValue(_count, _weight);
                          }
                        },
                      )
                    ],
            )
          ],
        ),
        if (widget.confirmChanges) ...[
          Defaults.sizedBox.horizontal.normal,
          IconButton(
            icon: const Icon(AppIcons.check),
            iconSize: 40,
            color: _count > 0 ? primaryColorOf(context) : null,
            onPressed:
                _count > 0 ? () => widget.setValue(_count, _weight) : null,
          ),
        ]
      ],
    );
  }
}
