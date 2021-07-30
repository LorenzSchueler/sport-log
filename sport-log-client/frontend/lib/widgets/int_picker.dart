
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntPicker extends StatefulWidget {
  const IntPicker({
    Key? key,
    required this.initialValue,
    required this.setValue,
  }) : super(key: key);

  final int initialValue;
  final Function(int) setValue;

  @override
  State<StatefulWidget> createState() => _IntPickerState(initialValue);
}

class _IntPickerState extends State<IntPicker> {
  _IntPickerState(this._value)
      : _controller = TextEditingController(text: "$_value"),
        super();

  Timer? _decreaseTimer;
  Timer? _increaseTimer;
  final TextEditingController _controller;
  int _value;

  static const _timeBetweenValueChanges = 80; // ms

  bool _isValidNumber(int number) {
    return number >= 1 && number <= 999;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          child: IconButton(
            icon: const Icon(Icons.indeterminate_check_box_rounded),
            onPressed: (_isValidNumber(_value - 1)) ? () {
              setState(() {
                _value -= 1;
              });
              _controller.text = "$_value";
              widget.setValue(_value);
            } : null,
          ),
          onTapDown: (details) {
            setState(() {
              _decreaseTimer = Timer.periodic(
                const Duration(milliseconds: _timeBetweenValueChanges),
                (timer) {
                  if (_isValidNumber(_value - 1)) {
                    setState(() {
                      _value -= 1;
                    });
                    _controller.text = "$_value";
                  }
              });
            });
          },
          onTapCancel: () {
            _decreaseTimer?.cancel();
            widget.setValue(_value);
          },
          onTapUp: (details) {
            _decreaseTimer?.cancel();
            widget.setValue(_value);
          },
        ),
        SizedBox(
          width: 30,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: _controller,
            textAlign: TextAlign.center,
            onChanged: (String text) {
              int v = int.parse(text);
              setState(() {
                _value = v;
              });
              widget.setValue(_value);
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
          ),
        ),
        GestureDetector(
          child: IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: (_isValidNumber(_value + 1)) ? () {
              setState(() {
                _value += 1;
              });
              _controller.text = "$_value";
              widget.setValue(_value);
            } : null,
          ),
          onTapDown: (details) {
            setState(() {
              _increaseTimer = Timer.periodic(
                  const Duration(milliseconds: _timeBetweenValueChanges),
                      (timer) {
                    if (_isValidNumber(_value + 1)) {
                      setState(() {
                        _value += 1;
                      });
                      _controller.text = "$_value";
                    }
                  });
            });
          },
          onTapCancel: () {
            _increaseTimer?.cancel();
            widget.setValue(_value);
          },
          onTapUp: (details) {
            _increaseTimer?.cancel();
            widget.setValue(_value);
          },
        ),
      ],
    );
  }
}