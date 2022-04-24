import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CountWeightInput extends StatefulWidget {
  /// If [this.dimension == MovementDimension.distance] [distanceUnit] and [editDistanceUnit] must not be null.
  const CountWeightInput({
    required this.setValue,
    required this.confirmChanges,
    required this.dimension,
    required this.editWeightUnit,
    this.distanceUnit,
    this.editDistanceUnit,
    this.initialCount = 0,
    this.initialWeight,
    this.secondWeight = false,
    this.initialSecondWeight,
    Key? key,
  }) : super(key: key);

  final void Function(
    int count,
    double? weight,
    double? secondWeight,
    DistanceUnit? distanceUnit,
  ) setValue;
  final bool confirmChanges;
  final MovementDimension dimension;
  final bool editWeightUnit;
  final DistanceUnit? distanceUnit;
  final bool? editDistanceUnit;
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
  late DistanceUnit? _distanceUnit;
  String _weightUnit = "kg";

  static const double _lbToKg = 0.45359237;

  @override
  void initState() {
    _count = widget.initialCount;
    _weight = widget.initialWeight;
    _secondWeight = widget.initialSecondWeight;
    _distanceUnit = widget.distanceUnit;
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
              if (widget.dimension == MovementDimension.distance &&
                  widget.editDistanceUnit!)
                EditTile(
                  leading: null,
                  caption: "Distance Unit",
                  child: SizedBox(
                    height: 24,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        value: _distanceUnit,
                        items: DistanceUnit.values
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit.name),
                              ),
                            )
                            .toList(),
                        onChanged: (unit) {
                          if (unit != null && unit is DistanceUnit) {
                            setState(() => _distanceUnit = unit);
                            if (!widget.confirmChanges) {
                              widget.setValue(
                                _count,
                                _weight,
                                _secondWeight,
                                _distanceUnit,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
              EditTile(
                leading: null,
                caption: widget.dimension == MovementDimension.distance
                    ? "${widget.dimension.displayName} (${_distanceUnit!.name})"
                    : widget.dimension.displayName,
                child: IntInput(
                  initialValue: _count,
                  setValue: (count) {
                    setState(() => _count = count);
                    if (!widget.confirmChanges) {
                      widget.setValue(
                        _count,
                        _weight,
                        _secondWeight,
                        _distanceUnit,
                      );
                    }
                  },
                ),
              ),
              if (_weight != null && widget.editWeightUnit)
                EditTile(
                  leading: null,
                  caption: "Weight Unit",
                  child: SizedBox(
                    height: 24,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        value: _weightUnit,
                        items: const [
                          DropdownMenuItem(
                            value: "kg",
                            child: Text("kg"),
                          ),
                          DropdownMenuItem(
                            value: "lb",
                            child: Text("lb"),
                          ),
                        ],
                        onChanged: (unit) {
                          if (unit != null &&
                              unit is String &&
                              unit != _weightUnit) {
                            setState(() {
                              _weightUnit = unit;
                              _weight = _weightUnit == "lb"
                                  ? _weight! * _lbToKg
                                  : _weight! / _lbToKg;
                              if (_secondWeight != null) {
                                _secondWeight = _weightUnit == "lb"
                                    ? _secondWeight! * _lbToKg
                                    : _secondWeight! / _lbToKg;
                              }
                            });
                            if (!widget.confirmChanges) {
                              widget.setValue(
                                _count,
                                _weight,
                                _secondWeight,
                                _distanceUnit,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
              if (_weight != null)
                EditTile(
                  leading: null,
                  caption: widget.secondWeight ? "Male Weight" : "Weight",
                  child: DoubleInput(
                    initialValue:
                        _weightUnit == "lb" ? _weight! / _lbToKg : _weight!,
                    stepSize: Settings.weightIncrement,
                    setValue: (weight) {
                      weight = _weightUnit == "lb" ? weight * _lbToKg : weight;
                      setState(() => _weight = weight);
                      if (!widget.confirmChanges) {
                        widget.setValue(
                          _count,
                          _weight,
                          _secondWeight,
                          _distanceUnit,
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
                    initialValue: _weightUnit == "lb"
                        ? _secondWeight! / _lbToKg
                        : _secondWeight!,
                    stepSize: Settings.weightIncrement,
                    setValue: (weight) {
                      weight = _weightUnit == "lb" ? weight * _lbToKg : weight;
                      setState(() => _secondWeight = weight);
                      if (!widget.confirmChanges) {
                        widget.setValue(
                          _count,
                          _weight,
                          _secondWeight,
                          _distanceUnit,
                        );
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
                          widget.setValue(
                            _count,
                            _weight,
                            _secondWeight,
                            _distanceUnit,
                          );
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
                          widget.setValue(
                            _count,
                            _weight,
                            _secondWeight,
                            _distanceUnit,
                          );
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
                    ? () => widget.setValue(
                          _count,
                          _weight,
                          _secondWeight,
                          _distanceUnit,
                        )
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
