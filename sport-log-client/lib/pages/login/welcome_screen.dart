import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.content, super.key});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(top: 200),
          child: Column(
            children: [
              const Icon(
                AppIcons.plan,
                size: 96,
              ),
              Defaults.sizedBox.vertical.big,
              const Text(
                "Sport Log",
                style: TextStyle(fontSize: 45),
              ),
              Defaults.sizedBox.vertical.normal,
              const Text(
                "License: GPLv3",
              ),
              Defaults.sizedBox.vertical.huge,
              content
            ],
          ),
        ),
      ),
    );
  }
}
