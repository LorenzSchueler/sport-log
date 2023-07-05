import 'package:flutter/material.dart' hide Route;
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
    return Row(
      children: [
        Expanded(
          child: ValueUnitDescription.distance(route.distance),
        ),
        Expanded(
          child: ValueUnitDescription.ascent(route.ascent),
        ),
        Expanded(
          child: ValueUnitDescription.descent(route.descent),
        ),
      ],
    );
  }
}
