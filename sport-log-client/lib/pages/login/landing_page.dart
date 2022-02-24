import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      content: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.login);
              },
              child: const Text("Login"),
            ),
          ),
          Defaults.sizedBox.horizontal.big,
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.registration);
              },
              child: const Text("Register"),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final Widget content;

  const WelcomeScreen({required this.content, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
