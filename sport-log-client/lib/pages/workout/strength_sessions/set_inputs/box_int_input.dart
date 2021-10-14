import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/helpers/extensions/text_editing_controller_extension.dart';
import 'package:sport_log/helpers/typedefs.dart';

/// Text Field with box that only accepts non-negative ints
class IntInput extends StatefulWidget {
  const IntInput({
    Key? key,
    required this.placeholder,
    required this.onChanged,
    required this.caption,
    required this.numberOfDigits,
    this.submitOnDigitsReached = false,
    this.onSubmitted,
    this.maxValue,
  })  : assert(numberOfDigits > 0),
        super(key: key);

  final int placeholder;
  final ChangeCallback<int> onChanged;
  final VoidCallback? onSubmitted;
  final String caption;
  final int numberOfDigits;
  final int? maxValue;
  final bool submitOnDigitsReached;

  static const double captionFontSize = 15;
  static const double textFontSize = 45;

  @override
  IntInputState createState() => IntInputState();
}

class IntInputState extends State<IntInput> {
  static const double _widthPerDigit = 34;

  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  void requestFocus() {
    _focusNode.requestFocus();
    _controller.selectAll();
  }

  void clear() {
    _controller.clear();
    widget.onChanged(widget.placeholder);
  }

  bool get hasFocus => _focusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _widthPerDigit * widget.numberOfDigits,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.caption,
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(fontSize: IntInput.captionFontSize),
          ),
          _textField,
        ],
      ),
    );
  }

  Widget get _textField {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      onSubmitted: (_) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!();
        }
      },
      focusNode: _focusNode,
      onTap: requestFocus,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction(_inputFormatter),
      ],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText:
            widget.placeholder.toString().padLeft(widget.numberOfDigits, '0'),
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(
        fontSize: IntInput.textFontSize,
      ),
      scrollPhysics: const NeverScrollableScrollPhysics(),
    );
  }

  void _onChanged(String text) {
    if (_controller.text.trim().isEmpty) {
      widget.onChanged(widget.placeholder);
      return;
    }
    final maybeValue = int.tryParse(_controller.text.trim());
    assert(maybeValue != null);
    if (maybeValue == null) {
      return;
    }
    assert(widget.maxValue == null || maybeValue <= widget.maxValue!);
    widget.onChanged(maybeValue);
    if (widget.submitOnDigitsReached &&
        maybeValue >= pow(10, widget.numberOfDigits - 1) &&
        widget.onSubmitted != null) {
      widget.onSubmitted!();
    }
  }

  TextEditingValue _inputFormatter(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text == newValue.text || newValue.text.isEmpty) {
      return newValue;
    }
    final value = int.parse(newValue.text);

    if (widget.maxValue != null && value > widget.maxValue! ||
        value >= pow(10, widget.numberOfDigits)) {
      return oldValue;
    }
    assert(newValue.selection.isCollapsed);
    final cursorPos = newValue.text.length - newValue.selection.start;
    final newText = value.toString().padLeft(widget.numberOfDigits, '0');
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length - cursorPos),
    );
  }
}
