import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class DurationInput extends StatefulWidget {
  const DurationInput({
    required this.setDuration,
    required this.initialDuration,
    this.durationIncrement,
    super.key,
  });

  final void Function(Duration)? setDuration;
  final Duration? initialDuration;
  final Duration? durationIncrement;

  @override
  State<DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late Duration _duration;

  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;

  static const double _textWidth = 13; // width of subtitle1 = 20 + cursor
  static const Duration _minTime = Duration.zero;
  static const Duration _maxTime = Duration(seconds: 60 * 100 - 1);

  late final _durationIncrement =
      widget.durationIncrement ?? Settings.instance.durationIncrement;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration ?? Duration.zero;
    _minutesController = TextEditingController(
      text: _duration.inMinutes.toString().padLeft(2, '0'),
    );
    _secondsController = TextEditingController(
      text: (_duration.inSeconds % 60).toString().padLeft(2, '0'),
    );
  }

  void _setDuration(Duration duration) {
    setState(() => _duration = duration);
    _minutesController.text = _duration.inMinutes.toString().padLeft(2, '0');
    _secondsController.text =
        (_duration.inSeconds % 60).toString().padLeft(2, '0');
    widget.setDuration?.call(_duration);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RepeatIconButton(
          icon: const Icon(AppIcons.subtractBox),
          onClick: _duration > _minTime
              ? () => _setDuration(_duration - _durationIncrement)
              : null,
        ),
        SizedBox(
          width: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _textWidth * 2,
                child: Focus(
                  child: TextFormField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: widget.setDuration != null,
                    onChanged: (minutes) {
                      if (Validator.validateMinOrSec(minutes) == null) {
                        setState(
                          () => _duration = Duration(
                            minutes: int.parse(minutes),
                            seconds: _duration.inSeconds % 60,
                          ),
                        );
                      }
                    },
                    decoration: const InputDecoration(
                      isCollapsed: true,
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
                  onFocusChange: (focus) {
                    if (!focus) {
                      widget.setDuration?.call(_duration);
                    }
                  },
                ),
              ),
              Text(':', style: Theme.of(context).textTheme.subtitle1),
              SizedBox(
                width: _textWidth * 2,
                child: Focus(
                  child: TextFormField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: widget.setDuration != null,
                    onChanged: (seconds) {
                      if (Validator.validateMinOrSec(seconds) == null) {
                        setState(
                          () => _duration = Duration(
                            minutes: _duration.inMinutes,
                            seconds: int.parse(seconds),
                          ),
                        );
                      }
                    },
                    decoration: const InputDecoration(
                      isCollapsed: true,
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
                  onFocusChange: (focus) {
                    if (!focus) {
                      widget.setDuration?.call(_duration);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        RepeatIconButton(
          icon: const Icon(AppIcons.addBox),
          onClick: _duration < _maxTime
              ? () => _setDuration(_duration + _durationIncrement)
              : null,
        ),
      ],
    );
  }
}
