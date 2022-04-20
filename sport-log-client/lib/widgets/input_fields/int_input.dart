import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class IntInput extends StatefulWidget {
  const IntInput({
    required this.setValue,
    this.initialValue = 0,
    this.stepSize = 1,
    Key? key,
  }) : super(key: key);

  final int initialValue;
  final int stepSize;
  final void Function(int value)? setValue;

  @override
  _IntInputState createState() => _IntInputState();
}

class _IntInputState extends State<IntInput> {
  late int _value;

  bool _showFormField = false;

  @override
  void initState() {
    _value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepeatIconButton(
          icon: const Icon(AppIcons.subtractBox),
          onClick: widget.setValue == null || _value <= 0
              ? null
              : () {
                  setState(() {
                    _value -= widget.stepSize;
                    _showFormField = false;
                  });
                  widget.setValue?.call(_value);
                },
        ),
        SizedBox(
          width: 70,
          child: _showFormField
              ? Focus(
                  child: TextFormField(
                    initialValue: "$_value",
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: widget.setValue != null,
                    onChanged: (value) {
                      final validated =
                          Validator.validateIntGeZeroLtValue(value, 1000);
                      if (validated == null) {
                        final v = int.parse(value);
                        setState(() => _value = v);
                        widget.setValue?.call(_value);
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  onFocusChange: (focus) =>
                      setState(() => _showFormField = focus),
                )
              : GestureDetector(
                  onTap: () => setState(
                    () => _showFormField = true,
                  ),
                  child: Text(
                    "$_value",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
        ),
        RepeatIconButton(
          icon: const Icon(AppIcons.addBox),
          onClick: widget.setValue == null
              ? null
              : () {
                  setState(() {
                    _value += widget.stepSize;
                    _showFormField = false;
                  });
                  widget.setValue?.call(_value);
                },
        ),
      ],
    );
  }
}
