import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class DurationInput extends StatefulWidget {
  const DurationInput({
    required this.onUpdate,
    required this.initialDuration,
    required this.minDuration,
    this.maxDuration = const Duration(minutes: 99, seconds: 59),
    this.durationIncrement,
    super.key,
  });

  final void Function(Duration) onUpdate;
  final Duration initialDuration;
  final Duration minDuration;
  final Duration maxDuration;

  /// defaults to Settings.instance.durationIncrement
  final Duration? durationIncrement;

  @override
  State<DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late Duration _duration = widget.initialDuration;
  late final _durationStep =
      widget.durationIncrement ?? Settings.instance.durationIncrement;

  late final TextEditingController _textController = TextEditingController(
    text: _duration.formatM99S,
  );

  void _setDuration(Duration duration, {required bool updateTextField}) {
    setState(() => _duration = duration);
    if (updateTextField) {
      // unfocus text field and thereby also close keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      _textController.text = _duration.formatM99S;
    }
    widget.onUpdate(_duration);
  }

  void _onTextSubmit() {
    final duration = _textController.text;
    final validated = _validateDuration(duration);
    if (validated != null) {
      showMessageDialog(context: context, text: validated);
    }
    _textController.text = _duration.formatM99S;
  }

  List<String> _parseMinSec(String duration) {
    var minutes = duration;
    var seconds = "0";
    if (duration.contains(":")) {
      final parts = duration.split(":");
      minutes = parts[0];
      seconds = parts[1];
    } else if (duration.contains(",")) {
      final parts = duration.split(",");
      minutes = parts[0];
      seconds = parts[1];
    } else if (duration.contains(".")) {
      final parts = duration.split(".");
      minutes = parts[0];
      seconds = parts[1];
    }
    return [minutes, seconds];
  }

  String? _validateDuration(String durationString) {
    var validated = Validator.validateStringNotEmpty(durationString);
    if (validated != null) {
      return validated;
    }
    final parts = _parseMinSec(durationString);
    final minutes = parts[0];
    final seconds = parts[1];
    validated = Validator.validateIntBetween(minutes, 0, 99);
    if (validated != null) {
      return validated;
    }
    validated = Validator.validateIntBetween(seconds, 0, 59);
    if (validated != null) {
      return validated;
    }
    final duration =
        Duration(minutes: int.parse(minutes), seconds: int.parse(seconds));
    if (duration < widget.minDuration) {
      return "The time must be greater than or equal to ${widget.minDuration.formatM99S}.";
    }
    if (duration > widget.maxDuration) {
      return "The time must be less than or equal to ${widget.maxDuration.formatM99S}.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepeatIconButton(
          icon: const Icon(AppIcons.subtractBox),
          onClick: _duration - _durationStep < widget.minDuration
              ? null
              : () => _setDuration(
                    _duration - _durationStep,
                    updateTextField: true,
                  ),
        ),
        SizedBox(
          width: 70,
          child: Focus(
            child: TextFormField(
              controller: _textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (duration) {
                if (_validateDuration(duration) == null) {
                  final parts = _parseMinSec(duration);
                  final minutes = int.parse(parts[0]);
                  final seconds = int.parse(parts[1]);
                  _setDuration(
                    Duration(minutes: minutes, seconds: seconds),
                    updateTextField: false,
                  ); // ignore error for now and report it on unfocus
                }
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
          onClick: _duration + _durationStep > widget.maxDuration
              ? null
              : () => _setDuration(
                    _duration + _durationStep,
                    updateTextField: true,
                  ),
        ),
      ],
    );
  }
}
