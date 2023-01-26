import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class DoubleInput extends StatefulWidget {
  const DoubleInput({
    required this.setValue,
    this.initialValue = 0,
    this.stepSize = 1,
    super.key,
  });

  final double initialValue;
  final double stepSize;
  final void Function(double value)? setValue;

  @override
  State<DoubleInput> createState() => _DoubleInputState();
}

class _DoubleInputState extends State<DoubleInput> {
  late double _value = widget.initialValue;

  late final TextEditingController _textController =
      TextEditingController(text: _value.toStringAsFixed(2));

  void _setValue(double value) {
    setState(() => _value = value);
    _textController.text = _value.toStringAsFixed(2);
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
          onClick: widget.setValue == null || _value < widget.stepSize
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
                final validated = Validator.validateDoubleGtZero(value);
                if (validated == null) {
                  final v = double.parse(value);
                  setState(() => _value = v);
                }
              },
              decoration: const InputDecoration(
                isCollapsed: true,
                isDense: true,
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.titleMedium,
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
          onClick: widget.setValue == null
              ? null
              : () => _setValue(_value + widget.stepSize),
        ),
      ],
    );
  }
}
