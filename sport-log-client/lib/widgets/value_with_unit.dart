import 'package:flutter/material.dart';

class ValueWithUnit extends StatelessWidget {
  final String value;
  final String? unit;

  const ValueWithUnit({
    Key? key,
    required this.value,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: unit == null ? value : "$value ",
          style: const TextStyle(fontSize: 20),
        ),
        TextSpan(
          text: unit,
          style: const TextStyle(fontSize: 14),
        )
      ]),
      textAlign: TextAlign.center,
    );
  }
}
