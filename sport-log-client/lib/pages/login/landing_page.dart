import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Landing"),
      ),
      body: Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.login);
            },
            child: const Text("Login"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.registration);
            },
            child: const Text("Register"),
          ),
        ],
      )),
    );
  }
}
