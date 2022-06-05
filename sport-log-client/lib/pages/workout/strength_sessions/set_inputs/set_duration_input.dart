import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/text_editing_controller_extension.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SetDurationInput extends StatefulWidget {
  const SetDurationInput({
    Key? key,
    required this.onNewSet,
    required this.confirmChanges,
  }) : super(key: key);

  final void Function(int count, double? weight, double? secondWeight) onNewSet;
  final bool confirmChanges;

  @override
  State<SetDurationInput> createState() => _SetDurationInputState();
}

class _SetDurationInputState extends State<SetDurationInput> {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _milliseconds = 0;

  final _hoursKey = GlobalKey<_PaddedIntInputState>();
  final _minutesKey = GlobalKey<_PaddedIntInputState>();
  final _secondsKey = GlobalKey<_PaddedIntInputState>();
  final _millisecondsKey = GlobalKey<_PaddedIntInputState>();

  void _submit() {
    final duration = Duration(
      hours: _hours,
      minutes: _minutes,
      seconds: _seconds,
      milliseconds: _milliseconds,
    );
    widget.onNewSet(duration.inMilliseconds, null, null);

    // clear all inputs
    _hoursKey.currentState?.clear();
    _minutesKey.currentState?.clear();
    _secondsKey.currentState?.clear();
    _millisecondsKey.currentState?.clear();

    // request focus on the right input
    if ((_hoursKey.currentState?.hasFocus ?? false) ||
        (_minutesKey.currentState?.hasFocus ?? false) ||
        (_secondsKey.currentState?.hasFocus ?? false) ||
        (_millisecondsKey.currentState?.hasFocus ?? false)) {
      if (duration.inHours != 0) {
        _hoursKey.currentState?.requestFocus();
      } else if (duration.inMinutes != 0) {
        _minutesKey.currentState?.requestFocus();
      } else if (duration.inSeconds != 0) {
        _secondsKey.currentState?.requestFocus();
      } else if (duration.inMilliseconds != 0) {
        _millisecondsKey.currentState?.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _timeInput,
        if (widget.confirmChanges) ...[
          Defaults.sizedBox.horizontal.normal,
          _addButton,
        ]
      ],
    );
  }

  Widget get _addButton {
    final isSubmittable =
        _hours != 0 || _minutes != 0 || _seconds != 0 || _milliseconds != 0;
    return IconButton(
      icon: const Icon(AppIcons.check),
      color: isSubmittable ? Theme.of(context).colorScheme.primary : null,
      iconSize: PaddedIntInput.fontSize,
      onPressed: isSubmittable ? _submit : null,
    );
  }

  Widget get _timeInput {
    return DefaultTextStyle(
      style: TextStyle(fontSize: PaddedIntInput.fontSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _hoursInput,
          const Text(':'),
          _minutesInput,
          const Text(':'),
          _secondsInput,
          const Text(','),
          _millisecondsInput,
        ],
      ),
    );
  }

  Widget get _hoursInput {
    return PaddedIntInput(
      key: _hoursKey,
      placeholder: 0,
      caption: 'h',
      numberOfDigits: 2,
      onChanged: (value) {
        setState(() => _hours = value);
        if (!widget.confirmChanges) {
          _submit();
        }
      },
      onSubmitted: () => _minutesKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _minutesInput {
    return PaddedIntInput(
      key: _minutesKey,
      placeholder: 0,
      caption: 'm',
      numberOfDigits: 2,
      maxValue: 59,
      onChanged: (value) {
        setState(() => _minutes = value);
        if (!widget.confirmChanges) {
          _submit();
        }
      },
      onSubmitted: () => _secondsKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _secondsInput {
    return PaddedIntInput(
      key: _secondsKey,
      placeholder: 0,
      caption: 's',
      numberOfDigits: 2,
      onChanged: (value) {
        setState(() => _seconds = value);
        if (!widget.confirmChanges) {
          _submit();
        }
      },
      onSubmitted: () => _millisecondsKey.currentState?.requestFocus(),
      submitOnDigitsReached: true,
    );
  }

  Widget get _millisecondsInput {
    return PaddedIntInput(
      key: _millisecondsKey,
      placeholder: 0,
      caption: 'ms',
      numberOfDigits: 3,
      onChanged: (value) {
        setState(() => _milliseconds = value);
        if (!widget.confirmChanges) {
          _submit();
        }
      },
    );
  }
}

class _CaptionTextField extends StatelessWidget {
  const _CaptionTextField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.caption,
    required this.placeholder,
    required this.formatFn,
    this.onSubmitted,
    required this.onTap,
    required this.width,
    required this.scrollable,
  }) : super(key: key);

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final String caption;
  final String placeholder;
  final TextInputFormatFunction formatFn;
  final VoidCallback? onSubmitted;
  final VoidCallback onTap;
  final double width;
  final bool scrollable;

  static const double captionFontSize = 15;
  static const double textFontSize = 40;

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
                .copyWith(fontSize: captionFontSize),
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
      onSubmitted: (_) => onSubmitted?.call(),
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
        fontSize: textFontSize,
      ),
      scrollPhysics: scrollable ? null : const NeverScrollableScrollPhysics(),
    );
  }
}

/// Text Field with box that only accepts non-negative ints
class PaddedIntInput extends StatefulWidget {
  const PaddedIntInput({
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
  final void Function(int) onChanged;
  final VoidCallback? onSubmitted;
  final String caption;
  final int numberOfDigits;
  final int? maxValue;
  final bool submitOnDigitsReached;

  static double get fontSize => _CaptionTextField.textFontSize;

  @override
  State<PaddedIntInput> createState() => _PaddedIntInputState();
}

class _PaddedIntInputState extends State<PaddedIntInput> {
  static const double _widthPerDigit = 31;

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
      onSubmitted: widget.onSubmitted,
      width: _widthPerDigit * widget.numberOfDigits,
      onTap: requestFocus,
      scrollable: false,
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
        maybeValue >= pow(10, widget.numberOfDigits - 1)) {
      widget.onSubmitted?.call();
    }
  }

  TextEditingValue _inputFormatter(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
