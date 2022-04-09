import 'package:flutter/material.dart';
import 'package:sport_log/models/action/action_event.dart';
import 'package:sport_log/models/action/action_provider_description.dart';

class ActionEventEditPage extends StatefulWidget {
  const ActionEventEditPage({
    required this.actionProviderDescription,
    required this.actionEvent,
    Key? key,
  }) : super(key: key);

  final ActionProviderDescription actionProviderDescription;
  final ActionEvent? actionEvent;

  @override
  State<ActionEventEditPage> createState() => _ActionEventEditPageState();
}

class _ActionEventEditPageState extends State<ActionEventEditPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
