import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/repeat_icon_button.dart';

class DoublePicker extends StatefulWidget {
  const DoublePicker({
    required this.setValue,
    this.initialValue = 0,
    this.stepSize = 2.5,
    Key? key,
  }) : super(key: key);

  final double initialValue;
  final double stepSize;
  final void Function(double value) setValue;

  @override
  _DoublePickerState createState() => _DoublePickerState();
}

class _DoublePickerState extends State<DoublePicker> {
  static const double _iconSize = 30;

  late double _value;

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
              width: 70,
              child: showFormField
                  ? Focus(
                      child: TextFormField(
                        initialValue: _value.toStringAsFixed(1),
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final validated =
                              Validator.validateDoubleGtZero(value);
                          if (validated == null) {
                            final v = double.parse(value);
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