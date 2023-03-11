import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class IntInput extends StatefulWidget {
  const IntInput({
    required this.onUpdate,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    this.stepSize = 1,
    super.key,
  });

  final void Function(int) onUpdate;
  final int initialValue;
  final int minValue;
  final int? maxValue;
  final int stepSize;

  @override
  State<IntInput> createState() => _IntInputState();
}

class _IntInputState extends State<IntInput> {
  late int _value = widget.initialValue;

  late final TextEditingController _textController =
      TextEditingController(text: _value.toString());

  void _setValue(int value, {required bool updateTextField}) {
    setState(() => _value = value);
    if (updateTextField) {
      _textController.text = _value.toString();
    }
    widget.onUpdate(_value);
  }

  void _onTextSubmit() {
    final value = _textController.text;
    final validated =
        Validator.validateIntBetween(value, widget.minValue, widget.maxValue);
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
                if (Validator.validateIntBetween(
                      value,
                      widget.minValue,
                      widget.maxValue,
                    ) ==
                    null) {
                  _setValue(int.parse(value), updateTextField: false);
                } // ignore error for now and report it on unfocus
              },
              decoration: const InputDecoration(
                isCollapsed: true,
                isDense: true,
                border: InputBorder.none,
              ),
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
