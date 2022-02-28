import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/repeat_icon_button.dart';

class IntPicker extends StatefulWidget {
  const IntPicker({
    required this.setValue,
    this.initialValue = 0,
    this.stepSize = 1,
    Key? key,
  }) : super(key: key);

  final int initialValue;
  final int stepSize;
  final void Function(int count) setValue;

  @override
  _IntPickerState createState() => _IntPickerState();
}

class _IntPickerState extends State<IntPicker> {
  static const double _iconSize = 30;

  late int _value;

  bool showFormField = false;

  @override
  void initState() {
    _value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          children: [
            RepeatIconButton(
              color: primaryColorOf(context),
              icon: const Icon(
                AppIcons.subtractBox,
                size: _iconSize,
              ),
              enabled: _value > 1,
              onClick: () {
                setState(() {
                  _value -= widget.stepSize;
                });
                widget.setValue(_value);
              },
              onRepeat: () {
                setState(() {
                  _value -= widget.stepSize;
                });
                widget.setValue(_value);
              },
            ),
            SizedBox(
              width: 40,
              child: showFormField
                  ? Focus(
                      child: TextFormField(
                        initialValue: "$_value",
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final validated =
                              Validator.validateIntGeZeroLtValue(value, 1000);
                          if (validated == null) {
                            final v = int.parse(value);
                            setState(() => _value = v);
                            widget.setValue(_value);
                          }
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                        ),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      onFocusChange: (focus) =>
                          setState(() => showFormField = focus),
                    )
                  : GestureDetector(
                      onTap: () => setState(
                        () => showFormField = true,
                      ),
                      child: Text(
                        "$_value",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ),
            ),
            RepeatIconButton(
              color: primaryColorOf(context),
              icon: const Icon(
                AppIcons.addBox,
                size: _iconSize,
              ),
              onClick: () {
                setState(() {
                  _value += widget.stepSize;
                });
                widget.setValue(_value);
              },
              onRepeat: () {
                setState(() {
                  _value += widget.stepSize;
                });
                widget.setValue(_value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
