import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _controller = TextEditingController();

  late int _value;

  @override
  void initState() {
    _value = widget.initialValue;
    _controller.text = '$_value';
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
                _controller.text = "$_value";
                widget.setValue(_value);
              },
              onRepeat: () {
                setState(() {
                  _value -= widget.stepSize;
                });
                _controller.text = "$_value";
                widget.setValue(_value);
              },
            ),
            SizedBox(
              width: 40,
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (String text) {
                  final v = int.tryParse(text);
                  if (v != null) {
                    setState(() => _value = v);
                    _controller.text = "$_value";
                    widget.setValue(_value);
                  }
                },
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    int? v = int.tryParse(newValue.text);
                    if (v == null || v < 0 || v > 999) {
                      return oldValue;
                    }
                    return newValue;
                  }),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                ),
                style: Theme.of(context).textTheme.headline5,
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
                _controller.text = "$_value";
                widget.setValue(_value);
              },
              onRepeat: () {
                setState(() {
                  _value += widget.stepSize;
                });
                _controller.text = "$_value";
                widget.setValue(_value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
