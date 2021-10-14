import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/helpers/extensions/text_editing_controller_extension.dart';
import 'package:sport_log/helpers/typedefs.dart';

class _CaptionTextField extends StatelessWidget {
  const _CaptionTextField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.caption,
    required this.placeholder,
    required this.formatFn,
    required this.onSubmitted,
    required this.onTap,
    required this.width,
  }) : super(key: key);

  final TextEditingController controller;
  final FocusNode focusNode;
  final ChangeCallback<String> onChanged;
  final String caption;
  final String placeholder;
  final TextInputFormatFunction formatFn;
  final VoidCallback onSubmitted;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            caption,
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
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      focusNode: focusNode,
      onTap: onTap,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        TextInputFormatter.withFunction(formatFn),
      ],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: placeholder,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(
        fontSize: IntInput.textFontSize,
      ),
      scrollPhysics: const NeverScrollableScrollPhysics(),
    );
  }
}

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
    return _CaptionTextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      caption: widget.caption,
      placeholder:
          widget.placeholder.toString().padLeft(widget.numberOfDigits, '0'),
      formatFn: _inputFormatter,
      onSubmitted: () {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!();
        }
      },
      width: _widthPerDigit * widget.numberOfDigits,
      onTap: requestFocus,
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
    final maybeValue = int.tryParse(newValue.text);
    if (maybeValue == null) {
      return oldValue;
    }
    final int value = maybeValue;

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
