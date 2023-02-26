import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/set_input/new_set_input.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';

class CountWeightInput extends StatefulWidget {
  /// If [this.dimension == MovementDimension.distance] [distanceUnit] and [editDistanceUnit] must not be null.
  const CountWeightInput({
    required this.onNewSet,
    required this.confirmChanges,
    required this.dimension,
    required this.editWeightUnit,
    required this.distanceUnit,
    required this.editDistanceUnit,
    required this.initialCount,
    required this.initialWeight,
    required this.secondWeight,
    required this.initialSecondWeight,
    super.key,
  });

  final void Function(
    int count,
    double? weight,
    double? secondWeight,
    DistanceUnit? distanceUnit,
  ) onNewSet;
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
  State<CountWeightInput> createState() => _CountWeightInputState();
}

class _CountWeightInputState extends State<CountWeightInput> {
  late int _count = widget.initialCount;
  late double? _weight = widget.initialWeight;
  late double? _secondWeight = widget.initialSecondWeight;
  late DistanceUnit? _distanceUnit = widget.distanceUnit;
  String _weightUnit = "kg";

  static const double _lbToKg = 0.45359237;

  void _submit({bool confirmed = false}) {
    if (!widget.confirmChanges || confirmed) {
      widget.onNewSet(
        _count,
        _weight,
        _secondWeight,
        _distanceUnit,
      );
    }
  }

  void _setCount(int count) {
    setState(() => _count = count);
    _submit();
  }

  void _setDistanceUnit(dynamic unit) {
    if (unit != null && unit is DistanceUnit) {
      setState(() => _distanceUnit = unit);
      _submit();
    }
  }

  void _setUnit(dynamic unit) {
    if (unit != null && unit is String && unit != _weightUnit) {
      setState(() {
        _weightUnit = unit;
        _weight = _weightUnit == "lb" ? _weight! * _lbToKg : _weight! / _lbToKg;
        if (_secondWeight != null) {
          _secondWeight = _weightUnit == "lb"
              ? _secondWeight! * _lbToKg
              : _secondWeight! / _lbToKg;
        }
      });
      _submit();
    }
  }

  void _setWeight(double weight) {
    setState(() => _weight = _weightUnit == "lb" ? weight * _lbToKg : weight);
    _submit();
  }

  void _setFemaleWeight(double weight) {
    setState(
      () => _secondWeight = _weightUnit == "lb" ? weight * _lbToKg : weight,
    );
    _submit();
  }

  void _addWeight() {
    setState(() {
      _weight = 0;
      _secondWeight = 0;
    });
    _submit();
  }

  void _removeWeight() {
    setState(() {
      _weight = null;
      _secondWeight = null;
    });
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Consumer<Settings>(
            builder: (context, settings, _) => Column(
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
                          onChanged: _setDistanceUnit,
                        ),
                      ),
                    ),
                  ),
                EditTile(
                  leading: null,
                  caption: widget.dimension == MovementDimension.distance
                      ? "${widget.dimension.name} (${_distanceUnit!.name})"
                      : widget.dimension.name,
                  child: IntInput(
                    initialValue: _count,
                    onUpdate: _setCount,
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
                          onChanged: _setUnit,
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
                      stepSize: settings.weightIncrement,
                      onUpdate: _setWeight,
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
                      stepSize: settings.weightIncrement,
                      onUpdate: _setFemaleWeight,
                    ),
                  ),
                _weight == null
                    ? ActionChip(
                        avatar: const Icon(AppIcons.add),
                        label: const Text("Add Weight"),
                        onPressed: _addWeight,
                      )
                    : ActionChip(
                        avatar: const Icon(AppIcons.close),
                        label: const Text("Remove Weight"),
                        onPressed: _removeWeight,
                      ),
              ],
            ),
          ),
        ),
        if (widget.confirmChanges)
          Expanded(
            child: Center(
              child: SubmitSetButton(
                isSubmittable: _count > 0 && (_weight == null || _weight! > 0),
                onSubmitted: () => _submit(confirmed: true),
              ),
            ),
          ),
      ],
    );
  }
}