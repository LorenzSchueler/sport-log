import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class IntInput extends StatefulWidget {
  const IntInput({
    required this.setValue,
    this.initialValue = 0,
    this.minValue = 0,
    this.maxValue = 999,
    this.stepSize = 1,
    super.key,
  });

  final int initialValue;
  final int minValue;
  final int maxValue;
  final int stepSize;
  final void Function(int value)? setValue;

  @override
  State<IntInput> createState() => _IntInputState();
}

class _IntInputState extends State<IntInput> {
  late int _value;

  late final TextEditingController _textController;

  @override
  void initState() {
    _value = widget.initialValue;
    _textController = TextEditingController(text: _value.toString());
    super.initState();
  }

  void _setValue(int value) {
    setState(() => _value = value);
    _textController.text = _value.toString();
    FocusManager.instance.primaryFocus?.unfocus();
    widget.setValue?.call(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepeatIconButton(
          icon: const Icon(AppIcons.subtractBox),
          onClick: widget.setValue == null || _value <= widget.minValue
              ? null
              : () => _setValue(_value - widget.stepSize),
        ),
        SizedBox(
          width: 70,
          child: Focus(
            child: TextFormField(
              controller: _textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              enabled: widget.setValue != null,
              onChanged: (value) {
                if (Validator.validateIntBetween(
                      value,
                      widget.minValue,
                      widget.maxValue,
                    ) ==
                    null) {
                  final v = int.parse(value);
                  setState(() => _value = v);
                }
              },
              decoration: const InputDecoration(
                isCollapsed: true,
                isDense: true,
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.subtitle1,
            ),
            onFocusChange: (focus) {
              if (!focus) {
                widget.setValue?.call(_value);
              }
            },
          ),
        ),
        RepeatIconButton(
          icon: const Icon(AppIcons.addBox),
          onClick: widget.setValue == null || _value >= widget.maxValue
              ? null
              : () => _setValue(_value + widget.stepSize),
        ),
      ],
    );
  }
}
