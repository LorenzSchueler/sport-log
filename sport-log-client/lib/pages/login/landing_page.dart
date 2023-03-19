import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/pages/login/welcome_screen.dart';
import 'package:sport_log/routes.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          ElevatedButton(
            onPressed: () {
              Account.noAccount();
              Navigator.of(context).newBase(Routes.timelineOverview);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.onBackground,
              ),
            ),
            child: const Text("Use Without Account"),
          ),
        ],
      ),
    );
  }
}
