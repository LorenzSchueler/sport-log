import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/action/action_rule.dart';

class ActionRuleEditPage extends StatefulWidget {
  const ActionRuleEditPage({
    required this.actionProviderDescription,
    required this.actionRule,
    Key? key,
  }) : super(key: key);

  final ActionProviderDescription actionProviderDescription;
  final ActionRule? actionRule;

  @override
  State<ActionRuleEditPage> createState() => _ActionRuleEditPageState();
}

class _ActionRuleEditPageState extends State<ActionRuleEditPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
