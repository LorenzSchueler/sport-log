import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class DurationInput extends StatefulWidget {
  const DurationInput({
    Key? key,
    required this.setDuration,
    required this.initialDuration,
  }) : super(key: key);

  final void Function(Duration)? setDuration;
  final Duration? initialDuration;

  @override
  State<DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late Duration _duration;

  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  late final StreamSubscription<bool> _keyboardSubscription;

  static const double _textWidth = 11; // width of subtitle1 = 20
  static const int _timeStep = 60; // seconds
  static const int _maxSeconds = 60 * 100 - 1;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration ?? Duration.zero;
    _updateTextFields();
    _keyboardSubscription = KeyboardVisibilityController()
        .onChange
        .listen(_onKeyboardVisibilityEvent);
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  Function(Duration duration, {required bool format})? get _setDuration =>
      widget.setDuration == null
          ? null
          : (
              Duration d, {
              required bool format,
            }) {
              setState(() => _duration = d);
              if (format) {
                _updateTextFields();
              }
              widget.setDuration?.call(_duration);
            };

  void _updateTextFields() {
    _minutesController.text = _duration.inMinutes.toString().padLeft(2, '0');
    final seconds = _duration.inSeconds % 60;
    _secondsController.text = seconds.toString().padLeft(2, '0');
  }

  void _onKeyboardVisibilityEvent(bool isVisible) {
    if (!isVisible) {
      FocusScope.of(context).unfocus();
      _updateTextFields();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _minusButton,
        Defaults.sizedBox.horizontal.normal,
        _minutesInput,
        Text(' : ', style: Theme.of(context).textTheme.subtitle1),
        _secondsInput,
        Defaults.sizedBox.horizontal.normal,
        _plusButton,
      ],
    );
  }

  Widget get _minusButton {
    return RepeatIconButton(
      icon: const Icon(AppIcons.subtractBox),
      onClick: _duration.inSeconds > 0 && _setDuration != null
          ? () {
              _setDuration?.call(
                Duration(seconds: max(0, _duration.inSeconds - _timeStep)),
                format: true,
              );
              FocusScope.of(context).unfocus();
            }
          : null,
    );
  }

  Widget get _plusButton {
    return RepeatIconButton(
      icon: const Icon(AppIcons.addBox),
      onClick: _duration.inSeconds < _maxSeconds && _setDuration != null
          ? () {
              _setDuration?.call(
                Duration(
                  seconds: min(_maxSeconds, _duration.inSeconds + _timeStep),
                ),
                format: true,
              );
              FocusScope.of(context).unfocus();
            }
          : null,
    );
  }

  Widget get _minutesInput {
    return SizedBox(
      width: _textWidth * 2,
      child: TextFormField(
        controller: _minutesController,
        keyboardType: TextInputType.number,
        enabled: widget.setDuration != null,
        onChanged: (minutes) {
          if (Validator.validateMinOrSec(minutes) == null) {
            _setDuration?.call(
              Duration(
                minutes: int.parse(minutes),
                seconds: _duration.inSeconds % 60,
              ),
              format: false,
            );
          }
        },
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          isDense: true,
          enabledBorder: InputBorder.none,
        ),
        validator: Validator.validateMinOrSec,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
      width: _textWidth * 2,
      child: TextFormField(
        controller: _secondsController,
        keyboardType: TextInputType.number,
        enabled: widget.setDuration != null,
        onChanged: (seconds) {
          if (Validator.validateMinOrSec(seconds) == null) {
            _setDuration?.call(
              Duration(
                minutes: _duration.inMinutes,
                seconds: int.parse(seconds),
              ),
              format: false,
            );
          }
        },
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          isDense: true,
          enabledBorder: InputBorder.none,
        ),
        validator: Validator.validateMinOrSec,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
}
