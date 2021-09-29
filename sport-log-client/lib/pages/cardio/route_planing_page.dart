import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/expandable_fab.dart';

class RoutePlanningPage extends StatelessWidget {
  const RoutePlanningPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ExampleExpandableFab();
  }
}

@immutable
class ExampleExpandableFab extends StatelessWidget {
  const ExampleExpandableFab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text("data");
  }
}
