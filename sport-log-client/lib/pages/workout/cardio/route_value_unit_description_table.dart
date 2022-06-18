import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RouteValueUnitDescriptionTable extends StatelessWidget {
  const RouteValueUnitDescriptionTable({
    required this.route,
    super.key,
  });

  final Route route;

  @override
  Widget build(BuildContext context) {
    final TableRow rowSpacer = TableRow(
      children: [
        Defaults.sizedBox.vertical.normal,
        Defaults.sizedBox.vertical.normal,
      ],
    );

    return Table(
      children: [
        TableRow(
          children: [
            ValueUnitDescription.distance(route.distance),
            ValueUnitDescription.name(route.name)
          ],
        ),
        rowSpacer,
        TableRow(
          children: [
            ValueUnitDescription.ascent(route.ascent),
            ValueUnitDescription.descent(route.descent),
          ],
        ),
      ],
    );
  }
}
