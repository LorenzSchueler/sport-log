import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/text_editing_controller_extension.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SetDurationInput extends StatefulWidget {
  SetDurationInput({
    required this.onNewSet,
    required this.confirmChanges,
    required int initialCount,
    super.key,
  }) : initialDuration = Duration(milliseconds: initialCount);

  final void Function(int count, double? weight, double? secondWeight) onNewSet;
  final bool confirmChanges;
  final Duration initialDuration;

  @override
  State<SetDurationInput> createState() => _SetDurationInputState();
}

class _SetDurationInputState extends State<SetDurationInput> {
  late int _hours = widget.initialDuration.inHours;
  late int _minutes = widget.initialDuration.inMinutes % 60;
  late int _seconds = widget.initialDuration.inSeconds % 60;
  late int _milliseconds = widget.initialDuration.inMilliseconds % 1000;

  final _hoursKey = GlobalKey<_PaddedIntInputState>();
  final _minutesKey = GlobalKey<_PaddedIntInputState>();
  final _secondsKey = GlobalKey<_PaddedIntInputState>();
  final _millisecondsKey = GlobalKey<_PaddedIntInputState>();

  void _submit({bool confirmed = false}) {
    if (!widget.confirmChanges || confirmed) {
      final duration = Duration(
        hours: _hours,
        minutes: _minutes,
        seconds: _seconds,
        milliseconds: _milliseconds,
      );
      widget.onNewSet(duration.inMilliseconds, null, null);

      if (confirmed) {
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
      iconSize: _PaddedIntInput.fontSize,
      onPressed: isSubmittable ? () => _submit(confirmed: true) : null,
    );
  }

  Widget get _timeInput {
    return DefaultTextStyle(
      style: TextStyle(fontSize: _PaddedIntInput.fontSize),
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
    return _PaddedIntInput(
      initialValue: _hours,
      key: _hoursKey,
      placeholder: 0,
      caption: 'h',
      numberOfDigits: 2,
      onChanged: (value) => setState(() => _hours = value),
      onSubmitted: () {
        _submit();
        _minutesKey.currentState?.requestFocus();
      },
      submitOnDigitsReached: true,
      textInputAction: TextInputAction.next,
    );
  }

  Widget get _minutesInput {
    return _PaddedIntInput(
      initialValue: _minutes,
      key: _minutesKey,
      placeholder: 0,
      caption: 'm',
      numberOfDigits: 2,
      maxValue: 59,
      onChanged: (value) => setState(() => _minutes = value),
      onSubmitted: () {
        _submit();
        _secondsKey.currentState?.requestFocus();
      },
      submitOnDigitsReached: true,
      textInputAction: TextInputAction.next,
    );
  }

  Widget get _secondsInput {
    return _PaddedIntInput(
      initialValue: _seconds,
      key: _secondsKey,
      placeholder: 0,
      caption: 's',
      numberOfDigits: 2,
      onChanged: (value) => setState(() => _seconds = value),
      onSubmitted: () {
        _submit();
        _millisecondsKey.currentState?.requestFocus();
      },
      submitOnDigitsReached: true,
      textInputAction: TextInputAction.next,
    );
  }

  Widget get _millisecondsInput {
    return _PaddedIntInput(
      initialValue: _milliseconds,
      key: _millisecondsKey,
      placeholder: 0,
      caption: 'ms',
      numberOfDigits: 3,
      onChanged: (value) {
        setState(() => _milliseconds = value);
      },
      onSubmitted: _submit,
      textInputAction: TextInputAction.done,
    );
  }
}

class _CaptionTextField extends StatelessWidget {
  const _CaptionTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.caption,
    required this.placeholder,
    required this.textInputAction,
    required this.formatFn,
    this.onSubmitted,
    required this.onTap,
    required this.width,
    required this.scrollable,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final String caption;
  final String placeholder;
  final TextInputAction textInputAction;
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
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      focusNode: focusNode,
      onTap: onTap,
      textInputAction: textInputAction,
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
class _PaddedIntInput extends StatefulWidget {
  const _PaddedIntInput({
    required this.initialValue,
    required this.placeholder,
    required this.onChanged,
    required this.caption,
    required this.numberOfDigits,
    required this.textInputAction,
    this.submitOnDigitsReached = false,
    this.onSubmitted,
    this.maxValue,
    super.key,
  }) : assert(numberOfDigits > 0);

  final int? initialValue;
  final int placeholder;
  final void Function(int) onChanged;
  final VoidCallback? onSubmitted;
  final String caption;
  final int numberOfDigits;
  final TextInputAction textInputAction;
  final int? maxValue;
  final bool submitOnDigitsReached;

  static double get fontSize => _CaptionTextField.textFontSize;

  @override
  State<_PaddedIntInput> createState() => _PaddedIntInputState();
}

class _PaddedIntInputState extends State<_PaddedIntInput> {
  static const double _widthPerDigit = 31;

  final _focusNode = FocusNode();
  late final _controller = TextEditingController(
    text: widget.initialValue?.toString().padLeft(widget.numberOfDigits, '0'),
  );

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
      textInputAction: widget.textInputAction,
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
