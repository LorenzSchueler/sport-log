import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/repeat_icon_button.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class DurationPicker extends StatefulWidget {
  const DurationPicker({
    Key? key,
    required this.setDuration,
    required this.initialDuration,
  }) : super(key: key);

  final void Function(Duration) setDuration;
  final Duration? initialDuration;

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late Duration _duration;

  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  late final StreamSubscription<bool> _keyboardSubscription;

  static const double _iconSize = 40;
  static const double _textWidth = 33;
  static const double _fontSize = 25;
  static const int _timeStep = 30; // seconds
  static const int _maxSeconds = 60 * 100 - 1;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration ?? const Duration();
    _updateTextFieldsWithPadding();
    _keyboardSubscription = KeyboardVisibilityController()
        .onChange
        .listen(_onKeyboardVisibilityEvent);
  }

  @override
  void didUpdateWidget(covariant DurationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setDuration(
      widget.initialDuration ?? const Duration(),
      notifyParent: false,
      format: true,
    );
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  void _setDuration(
    Duration d, {
    required bool notifyParent,
    required bool format,
  }) {
    if (d != _duration) {
      setState(() {
        _duration = d;
      });
      if (format) {
        _updateTextFieldsWithPadding();
      }
      if (notifyParent) {
        widget.setDuration(_duration);
      }
    }
  }

  void _updateTextFieldsWithPadding() {
    _minutesController.text = _duration.inMinutes.toString().padLeft(2, '0');
    final seconds = _duration.inSeconds % 60;
    _secondsController.text = seconds.toString().padLeft(2, '0');
  }

  void _increaseDuration({required bool notifyParent}) {
    final seconds = _duration.inSeconds;
    if (seconds <= _maxSeconds - _timeStep) {
      _setDuration(
        Duration(seconds: seconds + _timeStep),
        notifyParent: notifyParent,
        format: true,
      );
    } else if (seconds < _maxSeconds) {
      _setDuration(
        Duration(seconds: seconds + 1),
        notifyParent: notifyParent,
        format: true,
      );
    }
    FocusScope.of(context).unfocus();
  }

  void _decreaseDuration({required bool notifyParent}) {
    final seconds = _duration.inSeconds;
    if (seconds >= _timeStep) {
      _setDuration(
        Duration(seconds: seconds - _timeStep),
        notifyParent: notifyParent,
        format: true,
      );
    } else if (seconds > 0) {
      _setDuration(
        Duration(seconds: seconds - 1),
        notifyParent: notifyParent,
        format: true,
      );
    }
    FocusScope.of(context).unfocus();
  }

  void _onKeyboardVisibilityEvent(bool isVisible) {
    if (!isVisible) {
      FocusScope.of(context).unfocus();
      _updateTextFieldsWithPadding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _minusButton,
        Defaults.sizedBox.horizontal.normal,
        _minutesInput,
        _divider,
        _secondsInput,
        Defaults.sizedBox.horizontal.normal,
        _plusButton,
      ],
    );
  }

  Widget get _minusButton {
    return RepeatIconButton(
      color: primaryColorOf(context),
      icon: const Icon(
        AppIcons.subtractBox,
        size: _iconSize,
      ),
      enabled: _duration.inSeconds > 0,
      onClick: () => _decreaseDuration(notifyParent: true),
      onRepeat: () => _decreaseDuration(notifyParent: false),
      onRepeatEnd: () => widget.setDuration(_duration),
    );
  }

  Widget get _plusButton {
    return RepeatIconButton(
      color: primaryColorOf(context),
      icon: const Icon(
        AppIcons.addBox,
        size: _iconSize,
      ),
      enabled: _duration.inSeconds < _maxSeconds,
      onClick: () => _increaseDuration(notifyParent: true),
      onRepeat: () => _increaseDuration(notifyParent: false),
      onRepeatEnd: () => widget.setDuration(_duration),
    );
  }

  Widget get _minutesInput {
    return SizedBox(
      width: _textWidth,
      child: TextField(
        controller: _minutesController,
        keyboardType: TextInputType.number,
        onChanged: (text) {
          if (text.trim().isEmpty) {
            return;
          }
          final maybeMinutes = int.tryParse(text);
          if (maybeMinutes == null) {
            return;
          }
          final newDuration = Duration(
            minutes: maybeMinutes,
            seconds: _duration.inSeconds % 60,
          );
          _setDuration(newDuration, notifyParent: true, format: false);
        },
        style: const TextStyle(fontSize: _fontSize),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          isDense: true,
          enabledBorder: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.trim().isEmpty) {
              return newValue;
            }
            final number = int.tryParse(newValue.text);
            if (number == null || number < 0 || number >= 100) {
              return oldValue;
            }
            return newValue;
          })
        ],
      ),
    );
  }

  Widget get _secondsInput {
    return SizedBox(
      width: _textWidth,
      child: TextField(
        controller: _secondsController,
        keyboardType: TextInputType.number,
        onChanged: (text) {
          if (text.trim().isEmpty) {
            return;
          }
          final maybeSeconds = int.tryParse(text);
          if (maybeSeconds == null) {
            return;
          }
          final newDuration =
              Duration(minutes: _duration.inMinutes, seconds: maybeSeconds);
          _setDuration(newDuration, notifyParent: true, format: false);
        },
        style: const TextStyle(fontSize: _fontSize),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          isDense: true,
          enabledBorder: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.trim().isEmpty) {
              return newValue;
            }
            final number = int.tryParse(newValue.text);
            if (number == null || number < 0 || number > 59) {
              return oldValue;
            }
            return newValue;
          })
        ],
      ),
    );
  }

  Widget get _divider =>
      const Text(' : ', style: TextStyle(fontSize: _fontSize));
}
