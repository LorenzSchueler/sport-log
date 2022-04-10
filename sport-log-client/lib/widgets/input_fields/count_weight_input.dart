import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
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
    this.secondWeight = false,
    this.initialSecondWeight,
    Key? key,
  }) : super(key: key);

  final void Function(int count, double? weight, double? secondWeight) setValue;
  final bool confirmChanges;
  final String countLabel;
  final String? countUnit;
  final int initialCount;
  final double? initialWeight;
  final bool secondWeight;
  final double? initialSecondWeight;

  @override
  _CountWeightInputState createState() => _CountWeightInputState();
}

class _CountWeightInputState extends State<CountWeightInput> {
  late int _count;
  late double? _weight;
  late double? _secondWeight;

  @override
  void initState() {
    _count = widget.initialCount;
    _weight = widget.initialWeight;
    _secondWeight = widget.initialSecondWeight;
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
            2: FixedColumnWidth(118), // 24 + 70 + 24
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
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: IntInput(
                    initialValue: _count,
                    setValue: (count) {
                      if (count > 0) {
                        setState(() => _count = count);
                        if (!widget.confirmChanges) {
                          widget.setValue(_count, _weight, _secondWeight);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            TableRow(
              children: _weight == null
                  ? [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: IconButton(
                          icon: const Icon(AppIcons.add),
                          onPressed: () {
                            setState(() {
                              _weight = 0;
                              _secondWeight = 0;
                            });
                            if (!widget.confirmChanges) {
                              widget.setValue(_count, _weight, _secondWeight);
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(
                          "Weight",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Container(),
                    ]
                  : [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: IconButton(
                          icon: const Icon(AppIcons.close),
                          onPressed: () {
                            setState(() {
                              _weight = null;
                              _secondWeight = null;
                            });
                            if (!widget.confirmChanges) {
                              widget.setValue(_count, _weight, _secondWeight);
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(
                          "Weight",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: DoubleInput(
                          initialValue: _weight!,
                          setValue: (weight) {
                            setState(() => _weight = weight);
                            if (!widget.confirmChanges) {
                              widget.setValue(_count, _weight, _secondWeight);
                            }
                          },
                        ),
                      ),
                    ],
            ),
            if (widget.secondWeight)
              TableRow(
                children: _secondWeight == null
                    ? [
                        Container(),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Text(
                            "Female Weight",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Container(),
                      ]
                    : [
                        Container(),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Text(
                            "Female Weight",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: DoubleInput(
                            initialValue: _secondWeight!,
                            setValue: (weight) {
                              setState(() => _secondWeight = weight);
                              if (!widget.confirmChanges) {
                                widget.setValue(_count, _weight, _secondWeight);
                              }
                            },
                          ),
                        ),
                      ],
              )
          ],
        ),
        if (widget.confirmChanges)
          Expanded(
            child: Center(
              child: IconButton(
                icon: const Icon(AppIcons.check),
                iconSize: 40,
                onPressed: _count > 0 && (_weight == null || _weight! > 0)
                    ? () => widget.setValue(_count, _weight, _secondWeight)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
      ],
    );
  }
}
