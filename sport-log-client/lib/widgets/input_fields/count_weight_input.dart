import 'package:flutter/material.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
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
        SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditTile(
                leading: null,
                caption: widget.countUnit == null
                    ? widget.countLabel
                    : "${widget.countLabel} (${widget.countUnit!})",
                child: IntInput(
                  initialValue: _count,
                  setValue: (count) {
                    setState(() => _count = count);
                    if (!widget.confirmChanges) {
                      widget.setValue(_count, _weight, _secondWeight);
                    }
                  },
                ),
              ),
              if (_weight != null)
                EditTile(
                  leading: null,
                  caption: widget.secondWeight ? "Male Weight" : "Weight",
                  child: DoubleInput(
                    initialValue: _weight!,
                    stepSize: Settings.weightIncrement,
                    setValue: (weight) {
                      setState(() => _weight = weight);
                      if (!widget.confirmChanges) {
                        widget.setValue(
                          _count,
                          _weight,
                          _secondWeight,
                        );
                      }
                    },
                  ),
                ),
              if (widget.secondWeight && _secondWeight != null)
                EditTile(
                  leading: null,
                  caption: "Female Weight",
                  child: DoubleInput(
                    initialValue: _secondWeight!,
                    stepSize: Settings.weightIncrement,
                    setValue: (weight) {
                      setState(() => _secondWeight = weight);
                      if (!widget.confirmChanges) {
                        widget.setValue(_count, _weight, _secondWeight);
                      }
                    },
                  ),
                ),
              _weight == null
                  ? ActionChip(
                      avatar: const Icon(AppIcons.add),
                      label: const Text("Add Weight"),
                      onPressed: () {
                        setState(() {
                          _weight = 0;
                          _secondWeight = 0;
                        });
                        if (!widget.confirmChanges) {
                          widget.setValue(_count, _weight, _secondWeight);
                        }
                      },
                    )
                  : ActionChip(
                      avatar: const Icon(AppIcons.close),
                      label: const Text("Remove Weight"),
                      onPressed: () {
                        setState(() {
                          _weight = null;
                          _secondWeight = null;
                        });
                        if (!widget.confirmChanges) {
                          widget.setValue(_count, _weight, _secondWeight);
                        }
                      },
                    ),
            ],
          ),
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
