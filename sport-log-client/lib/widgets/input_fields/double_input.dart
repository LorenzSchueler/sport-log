import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class DoubleInput extends StatefulWidget {
  const DoubleInput({
    required this.onUpdate,
    this.initialValue = 0,
    this.minValue = 0,
    this.maxValue,
    this.stepSize = 1,
    super.key,
  });

  final double initialValue;
  final double minValue;
  final double? maxValue;
  final double stepSize;
  final void Function(double value) onUpdate;

  @override
  State<DoubleInput> createState() => _DoubleInputState();
}

class _DoubleInputState extends State<DoubleInput> {
  late double _value = widget.initialValue;

  late final TextEditingController _textController =
      TextEditingController(text: _value.toStringAsFixed(2));

  void _setValue(double value, {required bool updateTextField}) {
    setState(() => _value = value);
    if (updateTextField) {
      _textController.text = _value.toStringAsFixed(2);
    }
    widget.onUpdate(_value);
  }

  void _onTextSubmit() {
    final value = _textController.text;
    final validated = Validator.validateDoubleBetween(
      value,
      widget.minValue,
      widget.maxValue,
    );
    if (validated != null) {
      showMessageDialog(context: context, text: validated);
      _textController.text = "$_value";
    }
    // if value is valid it is already set
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepeatIconButton(
          icon: const Icon(AppIcons.subtractBox),
          onClick: _value - widget.stepSize < widget.minValue
              ? null
              : () =>
                  _setValue(_value - widget.stepSize, updateTextField: true),
        ),
        SizedBox(
          width: 70,
          child: Focus(
            child: TextFormField(
              controller: _textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (Validator.validateDoubleBetween(
                      value,
                      widget.minValue,
                      widget.maxValue,
                    ) ==
                    null) {
                  _setValue(double.parse(value), updateTextField: false);
                } // ignore error for now and report it on unfocus
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
                _onTextSubmit();
              }
            },
          ),
        ),
        RepeatIconButton(
          icon: const Icon(AppIcons.addBox),
          onClick: widget.maxValue != null &&
                  _value + widget.stepSize > widget.maxValue!
              ? null
              : () =>
                  _setValue(_value + widget.stepSize, updateTextField: true),
        ),
      ],
    );
  }
}
