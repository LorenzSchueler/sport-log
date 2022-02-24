import 'package:flutter/material.dart';

class ValueUnitDescription extends StatelessWidget {
  final String value;
  final String? unit;
  final String? description;
  final double scale;

  const ValueUnitDescription({
    Key? key,
    required this.value,
    required this.unit,
    required this.description,
    this.scale = 1,
  }) : super(key: key);

  List<TextSpan> get _textSpans {
    List<TextSpan> textSpans = [];
    textSpans.add(
      TextSpan(
        text: unit == null ? value : "$value ",
        style: TextStyle(fontSize: 20 * scale),
      ),
    );
    if (unit != null) {
      textSpans.add(
        TextSpan(
          text: unit,
          style: TextStyle(fontSize: 14 * scale),
        ),
      );
    }
    if (description != null) {
      textSpans.add(
        TextSpan(
          text: "\n$description",
          style: TextStyle(fontSize: 12 * scale),
        ),
      );
    }

    return textSpans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: _textSpans),
      textAlign: TextAlign.center,
    );
  }
}
