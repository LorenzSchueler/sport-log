import 'package:flutter/widgets.dart';

class ChartHeader extends StatelessWidget {
  const ChartHeader({required this.fields, super.key});

  final List<(String, Color)> fields;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: fields
          .map(
            (args) => Expanded(
              child: Text(
                args.$1,
                style: TextStyle(color: args.$2),
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList(),
    );
  }
}
